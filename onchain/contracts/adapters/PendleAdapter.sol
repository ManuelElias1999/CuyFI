// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";
import {IStandardizedYield} from "../interfaces/external/pendle/IStandardizedYield.sol";
import {IPrincipalToken} from "../interfaces/external/pendle/IPrincipalToken.sol";
import {IPYieldToken} from "../interfaces/external/pendle/IPYieldToken.sol";
import {IPMarket} from "../interfaces/external/pendle/IPMarket.sol";
import {IPendleRouter} from "../interfaces/external/pendle/IPendleRouter.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title PendleAdapter
 * @notice Adapter for Pendle Protocol yield farming (optimized for USDT single-asset vaults)
 * @dev Supports any deposit token that Pendle SY accepts (USDT, USDC, etc.)
 */
contract PendleAdapter is IProtocolAdapter {
    using SafeERC20 for IERC20;

    // ============ Immutables ============

    /// @notice The token accepted for deposits (e.g., USDT on the specific chain)
    address public immutable depositToken;

    /// @notice The receipt token (PT - Principal Token)
    address public immutable receiptToken;

    /// @notice Pendle market for this PT
    address public immutable market;

    /// @notice Pendle router for swaps
    address public immutable router;

    /// @notice Pendle Standardized Yield token
    IStandardizedYield public immutable sy;

    /// @notice Pendle Principal Token
    IPrincipalToken public immutable pt;

    /// @notice Pendle Yield Token (paired with PT)
    IPYieldToken public immutable yt;

    // ============ State Variables ============

    /// @notice Maps withdrawal request IDs to SY amounts
    mapping(bytes32 => uint256) public withdrawalAmounts;

    /// @notice Counter for unique request IDs
    uint256 private requestCounter;

    // ============ Errors ============

    error InvalidMarket();
    error InvalidDepositToken();
    error WithdrawalNotFound();

    // ============ Constructor ============

    /**
     * @notice Initialize the Pendle adapter
     * @param _depositToken The token to accept (e.g., USDT on this chain)
     * @param _market The Pendle market address for the PT
     * @param _router The Pendle router address
     * @dev Validates that the market exists and supports the deposit token
     */
    constructor(address _depositToken, address _market, address _router) {
        depositToken = _depositToken;
        market = _market;
        router = _router;

        // Get market components
        (address _sy, address _pt,) = IPMarket(_market).readTokens();
        if (_sy == address(0) || _pt == address(0)) revert InvalidMarket();

        sy = IStandardizedYield(_sy);
        pt = IPrincipalToken(_pt);
        yt = IPYieldToken(pt.YT());
        receiptToken = _pt;

        // Validate deposit token is supported by SY
        address[] memory tokensIn = sy.getTokensIn();
        bool validToken = false;
        for (uint256 i = 0; i < tokensIn.length; i++) {
            if (tokensIn[i] == _depositToken) {
                validToken = true;
                break;
            }
        }
        if (!validToken) revert InvalidDepositToken();
    }

    // ============ Staking Functions ============

    /**
     * @notice Stake deposit tokens into Pendle (USDT → SY → PT)
     * @param amount Amount of deposit token to stake
     * @return receipts Amount of PT tokens received
     * @dev Flow: depositToken → SY (mint) → PT (swap via router)
     */
    function stake(uint256 amount, bytes calldata) public returns (uint256 receipts) {
        // Transfer deposit token from vault to adapter
        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), amount);

        // Step 1: Deposit into SY (Standardized Yield)
        IERC20(depositToken).forceApprove(address(sy), amount);
        uint256 syAmount = sy.deposit(address(this), depositToken, amount, 0, false);

        // Step 2: Swap SY for PT using Pendle Router
        IERC20(address(sy)).forceApprove(router, syAmount);

        IPendleRouter.ApproxParams memory approx = IPendleRouter.ApproxParams({
            guessMin: 0,
            guessMax: type(uint256).max,
            guessOffchain: 0, // 0 = router will calculate
            maxIteration: 256,
            eps: 1e14 // 0.01% precision
        });

        IPendleRouter.LimitOrderData memory limit = IPendleRouter.LimitOrderData({
            limitRouter: address(0),
            epsSkipMarket: 0,
            normalFills: new IPendleRouter.FillOrderParams[](0),
            flashFills: new IPendleRouter.FillOrderParams[](0),
            optData: ""
        });

        // PT tokens are sent directly to msg.sender (the vault)
        (receipts,) = IPendleRouter(router).swapExactSyForPt(msg.sender, market, syAmount, 0, approx, limit);

        return receipts;
    }

    // ============ Unstaking Functions ============

    /**
     * @notice Request unstaking from Pendle (PT → SY, held for finalization)
     * @param receipts Amount of PT tokens to unstake
     * @return requestId Unique ID for this withdrawal request
     * @dev Flow: PT → SY (swap or redeem), SY held until finalization
     */
    function requestUnstake(uint256 receipts, bytes calldata) external returns (bytes32 requestId) {
        // Transfer PT tokens from vault to adapter
        IERC20(receiptToken).safeTransferFrom(msg.sender, address(this), receipts);

        // Generate unique request ID
        requestId = keccak256(abi.encodePacked(msg.sender, block.timestamp, requestCounter++));
        uint256 syAmount;

        // Check if PT is expired (can redeem 1:1 for SY)
        if (pt.isExpired()) {
            // After expiry: PT + YT → SY (1:1 redemption)
            IERC20(receiptToken).safeTransfer(address(yt), receipts);
            syAmount = yt.redeemPY(address(this));
        } else {
            // Before expiry: Swap PT → SY via router
            IERC20(receiptToken).forceApprove(router, receipts);

            IPendleRouter.LimitOrderData memory limit = IPendleRouter.LimitOrderData({
                limitRouter: address(0),
                epsSkipMarket: 0,
                normalFills: new IPendleRouter.FillOrderParams[](0),
                flashFills: new IPendleRouter.FillOrderParams[](0),
                optData: ""
            });

            (syAmount,) = IPendleRouter(router).swapExactPtForSy(address(this), market, receipts, 0, limit);
        }

        // Store SY amount for finalization
        withdrawalAmounts[requestId] = syAmount;

        return requestId;
    }

    /**
     * @notice Finalize unstaking (SY → depositToken, sent to caller)
     * @param requestId The withdrawal request ID
     * @return amount Amount of deposit tokens returned
     * @dev Flow: SY (redeem) → depositToken → msg.sender (vault)
     */
    function finalizeUnstake(bytes32 requestId) external returns (uint256 amount) {
        uint256 syAmount = withdrawalAmounts[requestId];
        if (syAmount == 0) revert WithdrawalNotFound();

        // Clear the request
        delete withdrawalAmounts[requestId];

        // Redeem SY for deposit token, send directly to msg.sender (vault)
        amount = sy.redeem(msg.sender, syAmount, depositToken, 0, false);

        return amount;
    }

    // ============ Rewards & Harvesting ============

    /**
     * @notice Harvest rewards from Pendle
     * @return tokens Array of reward token addresses
     * @return amounts Array of reward amounts
     * @dev Currently Pendle rewards are auto-compounded in SY, so this returns empty
     *      In future versions, could claim PENDLE governance tokens
     */
    function harvest() external pure returns (address[] memory tokens, uint256[] memory amounts) {
        tokens = new address[](0);
        amounts = new uint256[](0);
        return (tokens, amounts);
    }

    /**
     * @notice Get pending rewards (if any)
     * @return Pending reward amount
     * @dev Currently returns 0 as Pendle auto-compounds
     */
    function getPendingRewards() external pure returns (uint256) {
        return 0;
    }

    // ============ View Functions ============

    /**
     * @notice Preview how many deposit tokens you'd get for redeeming PT
     * @param receiptAmount Amount of PT tokens
     * @return Estimated deposit token amount
     * @dev Useful for calculating yields and withdrawal amounts
     */
    function getDepositTokenForReceipts(uint256 receiptAmount) public view returns (uint256) {
        if (pt.isExpired()) {
            // After expiry: 1:1 redemption via SY
            return sy.previewRedeem(depositToken, receiptAmount);
        }

        // Before expiry: Calculate via market rate
        uint256 ptToSyRate = IPMarket(market).getPtToSyRate(900); // 15 min TWAP
        uint256 syAmount = (receiptAmount * ptToSyRate) / 1e18;

        return sy.previewRedeem(depositToken, syAmount);
    }

    /**
     * @notice Check if a withdrawal request is ready to claim
     * @param requestId The request ID
     * @return True if claimable
     */
    function isWithdrawalClaimable(bytes32 requestId) external view returns (bool) {
        return withdrawalAmounts[requestId] > 0;
    }

    /**
     * @notice Get the protocol name
     * @return Protocol identifier
     */
    function getProtocolName() external pure returns (string memory) {
        return "Pendle";
    }

    // ============ IProtocolAdapter Implementation ============

    /**
     * @notice Deposit asset into protocol (IProtocolAdapter interface)
     * @param asset Asset to deposit (must match depositToken)
     * @param amount Amount to deposit
     * @return shares Amount of PT tokens received
     */
    function deposit(address asset, uint256 amount) external returns (uint256 shares) {
        require(asset == depositToken, "Invalid asset");
        return this.stake(amount, new bytes(0));
    }

    /**
     * @notice Withdraw from protocol (IProtocolAdapter interface)
     * @param shares Amount of PT tokens to withdraw
     * @return amount Amount of deposit tokens returned
     */
    function withdraw(uint256 shares) external returns (uint256 amount) {
        // Transfer PT from sender
        IERC20(receiptToken).safeTransferFrom(msg.sender, address(this), shares);

        // Swap PT for SY
        IERC20(receiptToken).forceApprove(router, shares);

        IPendleRouter.ApproxParams memory approx = IPendleRouter.ApproxParams({
            guessMin: 0,
            guessMax: type(uint256).max,
            guessOffchain: 0,
            maxIteration: 256,
            eps: 1e14
        });

        IPendleRouter.LimitOrderData memory limit = IPendleRouter.LimitOrderData({
            limitRouter: address(0),
            epsSkipMarket: 0,
            normalFills: new IPendleRouter.FillOrderParams[](0),
            flashFills: new IPendleRouter.FillOrderParams[](0),
            optData: ""
        });

        // Swap PT for SY
        (uint256 syAmount,) = IPendleRouter(router).swapExactPtForSy(address(this), market, shares, 0, limit);

        // Redeem SY for deposit token
        amount = sy.redeem(msg.sender, syAmount, depositToken, 0, false);

        return amount;
    }

    /**
     * @notice Get total value in protocol (IProtocolAdapter interface)
     * @return Total value in deposit token terms
     */
    function totalValue() external view returns (uint256) {
        uint256 ptBalance = IERC20(receiptToken).balanceOf(address(this));
        if (ptBalance == 0) return 0;

        return getDepositTokenForReceipts(ptBalance);
    }
}

