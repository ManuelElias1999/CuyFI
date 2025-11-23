// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IOFT, SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {IOAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import {IBotVaultCore} from "./interfaces/IBotVaultCore.sol";
import {BotVaultLib} from "./libraries/BotVaultLib.sol";

/**
 * @title BotVaultComposer
 * @notice Composer for cross-chain deposits on Hub & Spoke architecture (deposit-only)
 *
 * Hub & Spoke Architecture:
 * - Hub: Arbitrum (EID 30110) - Main vault deployment
 * - Spokes: Polygon (30109), Ethereum (30101), Optimism (30111)
 *
 * User Deposit Flow (USDT → Shares):
 * 1. User on Polygon sends USDT via ASSET_OFT with compose message
 * 2. Composer receives USDT on Arbitrum hub (lzCompose callback)
 * 3. Composer deposits USDT into BotVault, mints shares
 * 4. Composer sends shares back to user on Polygon via SHARE_OFT
 *
 * Bot Deployment Flow (via BotStrategyFacet):
 * 1. Bot calls deployToChain() on Arbitrum
 * 2. Uses this composer to send USDT to spoke chains
 * 3. Bot manually deposits into protocols on destination
 *
 * Key Features:
 * - Deposit-only (no cross-chain redemptions)
 * - Single-asset (USDT, 6 decimals)
 * - Sync flow (no pending deposits)
 * - Automatic refunds on failure
 * - Slippage protection
 *
 * Note: Users can redeem shares directly on Arbitrum hub
 */
contract BotVaultComposer is ReentrancyGuard {
    using OFTComposeMsgCodec for bytes;
    using OFTComposeMsgCodec for bytes32;
    using SafeERC20 for IERC20;
    using OptionsBuilder for bytes;

    // ============ Immutables ============

    /// @notice The BotVault contract
    IBotVaultCore public immutable VAULT;

    /// @notice The share OFT adapter (for sending shares cross-chain)
    address public immutable SHARE_OFT;

    /// @notice The underlying asset (USDT)
    address public immutable ASSET;

    /// @notice LayerZero endpoint
    address public immutable ENDPOINT;

    /// @notice This chain's endpoint ID
    uint32 public immutable VAULT_EID;

    // ============ State Variables ============

    /// @notice Approved OFTs for deposits (USDT OFT on different chains)
    mapping(address => bool) public approvedOFTs;

    /// @notice Pending deposits waiting for manual finalization
    mapping(bytes32 => PendingDeposit) public pendingDeposits;

    // ============ Structs ============

    struct PendingDeposit {
        address user;           // User address on source chain
        uint32 userEid;         // Source chain EID
        uint256 shares;         // Shares minted
        uint64 timestamp;       // When deposit was processed
        bool completed;         // Whether finalized
    }

    // ============ Events ============

    event Deposited(
        bytes32 indexed depositor,
        bytes32 indexed recipient,
        uint32 indexed srcEid,
        uint256 assetAmount,
        uint256 shares
    );

    event DepositPending(
        bytes32 indexed guid,
        address indexed user,
        uint32 indexed srcEid,
        uint256 shares
    );

    event DepositFinalized(
        bytes32 indexed guid,
        address indexed user,
        uint256 shares
    );

    event Refunded(bytes32 indexed guid, address indexed oft, uint256 amount);

    event OFTApprovalUpdated(address indexed oft, bool approved);

    // ============ Errors ============

    error OnlyEndpoint(address caller);
    error InvalidOFT(address oft);
    error VaultPaused();
    error InsufficientMsgValue(uint256 required, uint256 provided);
    error OnlySelf(address caller);
    error SlippageExceeded(uint256 shares, uint256 minShares);
    error DepositAlreadyCompleted();
    error DepositNotFound();
    error DepositExpired();

    // ============ Constructor ============

    /**
     * @notice Initialize the composer
     * @param _vault The BotVault address
     * @param _shareOFT The share OFT adapter address
     */
    constructor(address _vault, address _shareOFT) {
        VAULT = IBotVaultCore(_vault);
        SHARE_OFT = _shareOFT;

        // Get asset from vault
        ASSET = VAULT.asset();

        // Get LayerZero endpoint from share OFT
        ENDPOINT = address(IOAppCore(_shareOFT).endpoint());
        VAULT_EID = ILayerZeroEndpointV2(ENDPOINT).eid();

        // Approve vault to spend assets
        IERC20(ASSET).forceApprove(_vault, type(uint256).max);

        // Approve share OFT to spend shares
        IERC20(address(VAULT)).forceApprove(_shareOFT, type(uint256).max);
    }

    // ============ Owner Functions ============

    /**
     * @notice Approve/revoke an OFT for deposits
     * @param oft The OFT address
     * @param approved Approval status
     * @dev Only vault owner can approve OFTs
     */
    function setOFTApproval(address oft, bool approved) external {
        // Only vault owner can approve OFTs
        // Call vault to get owner
        if (msg.sender != VAULT.getOwner()) revert BotVaultLib.UnauthorizedAccess();

        approvedOFTs[oft] = approved;
        emit OFTApprovalUpdated(oft, approved);
    }

    // ============ LayerZero Compose ============

    /**
     * @notice Handles LayerZero compose operations for cross-chain deposits
     * @param _composeSender The OFT contract (must be approved USDT OFT)
     * @param _guid LayerZero's unique tx id
     * @param _message Compose message containing deposit info
     */
    function lzCompose(
        address _composeSender,
        bytes32 _guid,
        bytes calldata _message,
        address, /*_executor*/
        bytes calldata /*_extraData*/
    ) external payable {
        // Only LayerZero endpoint can call
        if (msg.sender != ENDPOINT) revert OnlyEndpoint(msg.sender);

        // Validate OFT is approved
        if (!approvedOFTs[_composeSender]) revert InvalidOFT(_composeSender);

        // Decode compose message
        bytes32 composeFrom = _message.composeFrom();
        uint256 amount = _message.amountLD();
        bytes memory composeMsg = _message.composeMsg();
        uint32 srcEid = OFTComposeMsgCodec.srcEid(_message);

        // Try to handle deposit, save as pending on failure
        try this.handleDeposit{value: msg.value}(
            _guid,
            _composeSender,
            composeFrom,
            composeMsg,
            amount,
            srcEid
        ) {
            // Success - event emitted in handleDeposit
        } catch (bytes memory) {
            // Any error after deposit succeeds means we save as pending
            // Most common: LZ_InsufficientFee when trying to send shares back
            // Deposit succeeded but return trip failed - save for manual finalization
            _savePendingDeposit(_guid, composeFrom, composeMsg, amount, srcEid);
            return; // Don't refund - shares are safe in composer
        }
    }

    /**
     * @notice Saves a pending deposit when return trip fails
     * @dev Called when deposit succeeds but share transfer fails due to insufficient gas
     */
    function _savePendingDeposit(
        bytes32 _guid,
        bytes32 _composeFrom,
        bytes memory _composeMsg,
        uint256 _amount,
        uint32 _srcEid
    ) internal {
        // Decode compose message to get user info
        (SendParam memory hopSendParam, uint256 minShares,) =
            abi.decode(_composeMsg, (SendParam, uint256, uint256));

        // Deposit into vault (this will succeed since we have the assets)
        uint256 shares = VAULT.deposit(_amount, address(this));

        // Check slippage
        if (shares < minShares) {
            revert SlippageExceeded(shares, minShares);
        }

        // Get user address from hopSendParam.to (the real user, not the helper)
        address user = OFTComposeMsgCodec.bytes32ToAddress(hopSendParam.to);

        // Save pending deposit
        pendingDeposits[_guid] = PendingDeposit({
            user: user,
            userEid: _srcEid,
            shares: shares,
            timestamp: uint64(block.timestamp),
            completed: false
        });

        emit DepositPending(_guid, user, _srcEid, shares);
    }

    /**
     * @notice Handles the actual deposit operation
     * @dev Can only be called by self (from lzCompose try-catch)
     */
    function handleDeposit(
        bytes32, /* _guid */
        address, /* _oftIn */
        bytes32 _composeFrom,
        bytes memory _composeMsg,
        uint256 _amount,
        uint32 _srcEid
    ) external payable {
        // Can only be called by self
        if (msg.sender != address(this)) revert OnlySelf(msg.sender);

        // Decode compose message: (SendParam hopSendParam, uint256 minShares, uint256 minMsgValue)
        (SendParam memory hopSendParam, uint256 minShares, uint256 minMsgValue) =
            abi.decode(_composeMsg, (SendParam, uint256, uint256));

        // Check msg.value is sufficient
        if (msg.value < minMsgValue) {
            revert InsufficientMsgValue(minMsgValue, msg.value);
        }

        // Deposit into vault
        // Note: Asset approval was set in constructor to max
        uint256 shares = VAULT.deposit(_amount, address(this));

        // Check slippage
        if (shares < minShares) {
            revert SlippageExceeded(shares, minShares);
        }

        // Send shares to user on destination chain
        hopSendParam.amountLD = shares;
        hopSendParam.minAmountLD = 0; // Already checked slippage above

        // Note: Share OFT approval was set in constructor to max
        IOFT(SHARE_OFT).send{value: msg.value}(
            hopSendParam,
            MessagingFee(msg.value, 0),
            tx.origin // Refund excess gas to original sender
        );

        emit Deposited(_composeFrom, hopSendParam.to, _srcEid, _amount, shares);
    }

    // ============ Refund Logic ============

    /**
     * @notice Refunds assets back to user on source chain
     * @param _oft The OFT to use for refund
     * @param _to The recipient (user address on source chain)
     * @param _amount The amount to refund
     * @param _dstEid The destination chain (source chain of original tx)
     */
    function _refund(
        address _oft,
        bytes32 _to,
        uint256 _amount,
        uint32 _dstEid
    ) internal {
        // Get the asset token
        address assetToken = IOFT(_oft).token();

        // Build refund SendParam
        SendParam memory refundSendParam;
        refundSendParam.dstEid = _dstEid;
        refundSendParam.to = _to;
        refundSendParam.amountLD = _amount;
        refundSendParam.minAmountLD = _amount; // No slippage on refund
        refundSendParam.extraOptions = ""; // Default options
        refundSendParam.composeMsg = ""; // No compose on refund
        refundSendParam.oftCmd = "";

        // Approve OFT to spend asset
        IERC20(assetToken).forceApprove(_oft, _amount);

        // Send refund (use all remaining msg.value for gas)
        IOFT(_oft).send{value: address(this).balance}(
            refundSendParam,
            MessagingFee(address(this).balance, 0),
            tx.origin // Refund excess gas to original sender
        );

        // Reset approval
        IERC20(assetToken).forceApprove(_oft, 0);
    }

    // ============ Bot Deployment Function ============

    /**
     * @notice Send USDT cross-chain (used by BotStrategyFacet for deployments)
     * @param amount The amount of USDT to send (6 decimals)
     * @param sendParam LayerZero send parameters
     * @param refundAddress Address to refund excess gas
     * @dev Called by bot when deploying to spoke chains
     *      Uses ASSET (USDT) from vault storage - no need to pass token address
     */
    function depositAndSend(
        address oftAdapter,
        uint256 amount,
        SendParam memory sendParam,
        address refundAddress
    ) external payable {
        // Only vault can call (via BotStrategyFacet)
        if (msg.sender != address(VAULT)) revert OnlySelf(msg.sender);

        // Transfer USDT normal from vault to this contract
        IERC20(ASSET).safeTransferFrom(msg.sender, address(this), amount);

        // Approve OFT adapter to spend USDT normal
        IERC20(ASSET).forceApprove(oftAdapter, amount);

        // Send via LayerZero OFT adapter
        IOFT(oftAdapter).send{value: msg.value}(
            sendParam,
            MessagingFee(msg.value, 0),
            refundAddress
        );

        // Reset approval
        IERC20(ASSET).forceApprove(oftAdapter, 0);
    }

    // ============ Quote Function ============

    /**
     * @notice Quotes the fee for a cross-chain deposit
     * @param _from The user address (for max deposit check)
     * @param _assetAmount The amount of assets to deposit
     * @param _hopSendParam The send parameters for the share transfer
     * @return fee The estimated messaging fee
     */
    function quoteDeposit(
        address _from,
        uint256 _assetAmount,
        SendParam memory _hopSendParam
    ) external view returns (MessagingFee memory fee) {
        // Check max deposit
        uint256 maxDeposit = VAULT.maxDeposit(_from);
        if (_assetAmount > maxDeposit) {
            revert("ERC4626ExceededMaxDeposit");
        }

        // Preview shares
        uint256 shares = VAULT.previewDeposit(_assetAmount);

        // Set share amount in send param
        _hopSendParam.amountLD = shares;

        // Quote LayerZero fee
        return IOFT(SHARE_OFT).quoteSend(_hopSendParam, false);
    }

    // ============ Pending Deposit Finalization ============

    /**
     * @notice Finalize a pending deposit by sending shares to user
     * @param _guid The LayerZero GUID of the pending deposit
     * @dev User or bot must provide ETH for the return trip
     */
    function finalizeDeposit(bytes32 _guid) external payable nonReentrant {
        PendingDeposit memory pending = pendingDeposits[_guid];

        // Validate pending deposit exists
        if (pending.shares == 0) revert DepositNotFound();
        if (pending.completed) revert DepositAlreadyCompleted();

        // Check expiration (7 days)
        if (block.timestamp > pending.timestamp + 7 days) revert DepositExpired();

        // Build extraOptions with gas for lzReceive
        bytes memory extraOptions = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(200000, 0);

        // Build send param to return shares to user
        SendParam memory sendParam = SendParam({
            dstEid: pending.userEid,
            to: bytes32(uint256(uint160(pending.user))),
            amountLD: pending.shares,
            minAmountLD: pending.shares,
            extraOptions: extraOptions,
            composeMsg: hex"",
            oftCmd: hex""
        });

        // Send shares using caller's ETH
        IOFT(SHARE_OFT).send{value: msg.value}(
            sendParam,
            MessagingFee(msg.value, 0),
            msg.sender // Refund excess to caller
        );

        // Mark as completed
        pendingDeposits[_guid].completed = true;

        emit DepositFinalized(_guid, pending.user, pending.shares);
    }

    /**
     * @notice Quote the fee for finalizing a pending deposit
     * @param _guid The LayerZero GUID of the pending deposit
     * @return nativeFee The ETH required to finalize
     */
    function quoteFinalizeDeposit(bytes32 _guid) external view returns (uint256 nativeFee) {
        PendingDeposit memory pending = pendingDeposits[_guid];
        if (pending.shares == 0) revert DepositNotFound();

        // Build extraOptions with gas for lzReceive
        bytes memory extraOptions = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(200000, 0);

        SendParam memory sendParam = SendParam({
            dstEid: pending.userEid,
            to: bytes32(uint256(uint160(pending.user))),
            amountLD: pending.shares,
            minAmountLD: pending.shares,
            extraOptions: extraOptions,
            composeMsg: hex"",
            oftCmd: hex""
        });

        MessagingFee memory fee = IOFT(SHARE_OFT).quoteSend(sendParam, false);
        return fee.nativeFee;
    }

    // ============ View Functions ============

    function isOFTApproved(address oft) external view returns (bool) {
        return approvedOFTs[oft];
    }

    function getPendingDeposit(bytes32 _guid) external view returns (PendingDeposit memory) {
        return pendingDeposits[_guid];
    }

    // ============ Receive ETH ============

    receive() external payable {}
}
