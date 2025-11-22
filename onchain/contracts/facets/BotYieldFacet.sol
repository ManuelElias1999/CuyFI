// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {BotVaultLib} from "../libraries/BotVaultLib.sol";
import {IBotYield} from "../interfaces/IBotYield.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";

/**
 * @title BotYieldFacet
 * @notice Yield farming facet supporting multiple protocols via adapters
 * @dev Uses adapter pattern for extensibility (Aave, Compound, Pendle, etc.)
 */
contract BotYieldFacet is IBotYield, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Modifiers ============

    modifier onlyAgent() {
        BotVaultLib.enforceIsAgent();
        _;
    }

    modifier onlyOwnerOrAgent() {
        BotVaultLib.enforceIsOwnerOrAgent();
        _;
    }

    // ============ Yield Operations ============

    /**
     * @notice Deposit assets into a yield protocol via adapter
     * @dev Agent calls this to deploy funds into Aave, Compound, Pendle, etc.
     * @param protocolAdapter Address of the protocol adapter
     * @param amount Amount to deposit
     * @param data Protocol-specific data
     * @return receipts Receipt tokens received (aTokens, cTokens, PT tokens, etc.)
     */
    function depositToProtocol(address protocolAdapter, uint256 amount, bytes calldata data)
        external
        override
        onlyAgent
        nonReentrant
        returns (uint256 receipts)
    {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        if (!ds.approvedProtocols[protocolAdapter]) revert ProtocolNotApproved(protocolAdapter);
        if (amount == 0) revert ZeroAmount();

        // Get deposit token from adapter
        address depositToken = IProtocolAdapter(protocolAdapter).depositToken();

        // Approve protocol adapter
        IERC20(depositToken).forceApprove(protocolAdapter, amount);

        // Deposit via adapter
        receipts = IProtocolAdapter(protocolAdapter).stake(amount, data);

        // Reset approval
        IERC20(depositToken).forceApprove(protocolAdapter, 0);

        emit DepositedToProtocol(protocolAdapter, depositToken, amount, receipts);

        return receipts;
    }

    /**
     * @notice Request withdrawal from a yield protocol
     * @dev Some protocols (like Pendle) require 2-step withdrawal
     * @param protocolAdapter Address of the protocol adapter
     * @param receipts Amount of receipt tokens to withdraw
     * @param data Protocol-specific data
     * @return requestId Withdrawal request ID (for 2-step withdrawals)
     */
    function requestWithdrawal(address protocolAdapter, uint256 receipts, bytes calldata data)
        external
        override
        onlyAgent
        nonReentrant
        returns (bytes32 requestId)
    {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        if (!ds.approvedProtocols[protocolAdapter]) revert ProtocolNotApproved(protocolAdapter);
        if (receipts == 0) revert ZeroAmount();

        // Get receipt token from adapter
        address receiptToken = IProtocolAdapter(protocolAdapter).receiptToken();

        // Approve protocol adapter
        IERC20(receiptToken).forceApprove(protocolAdapter, receipts);

        // Request withdrawal via adapter
        requestId = IProtocolAdapter(protocolAdapter).requestUnstake(receipts, data);

        // Reset approval
        IERC20(receiptToken).forceApprove(protocolAdapter, 0);

        emit WithdrawalRequested(protocolAdapter, receipts, requestId);

        return requestId;
    }

    /**
     * @notice Finalize withdrawal from a yield protocol
     * @dev Completes 2-step withdrawal process
     * @param protocolAdapter Address of the protocol adapter
     * @param requestId Withdrawal request ID
     * @return amount Amount of underlying assets received
     */
    function finalizeWithdrawal(address protocolAdapter, bytes32 requestId)
        external
        override
        onlyAgent
        nonReentrant
        returns (uint256 amount)
    {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        if (!ds.approvedProtocols[protocolAdapter]) revert ProtocolNotApproved(protocolAdapter);

        // Finalize withdrawal via adapter
        amount = IProtocolAdapter(protocolAdapter).finalizeUnstake(requestId);

        emit WithdrawalFinalized(protocolAdapter, requestId, amount);

        return amount;
    }

    /**
     * @notice Harvest rewards from a protocol
     * @dev Claims accumulated rewards (e.g., COMP, AAVE, PENDLE tokens)
     * @param protocolAdapter Address of the protocol adapter
     * @return tokens Array of reward token addresses
     * @return amounts Array of reward amounts
     */
    function harvestRewards(address protocolAdapter)
        external
        override
        onlyAgent
        nonReentrant
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        if (!ds.approvedProtocols[protocolAdapter]) revert ProtocolNotApproved(protocolAdapter);

        // Harvest via adapter
        (tokens, amounts) = IProtocolAdapter(protocolAdapter).harvest();

        emit RewardsHarvested(protocolAdapter, tokens, amounts);

        return (tokens, amounts);
    }

    // ============ View Functions ============

    /**
     * @notice Get pending rewards for a protocol
     */
    function getPendingRewards(address protocolAdapter) external view override returns (uint256) {
        return IProtocolAdapter(protocolAdapter).getPendingRewards();
    }

    /**
     * @notice Check if a withdrawal is claimable
     */
    function isWithdrawalClaimable(address protocolAdapter, bytes32 requestId)
        external
        view
        override
        returns (bool)
    {
        return IProtocolAdapter(protocolAdapter).isWithdrawalClaimable(requestId);
    }

    /**
     * @notice Get protocol name from adapter
     */
    function getProtocolName(address protocolAdapter) external pure override returns (string memory) {
        return IProtocolAdapter(protocolAdapter).getProtocolName();
    }

    /**
     * @notice Preview withdrawal amount
     */
    function getWithdrawalAmount(address protocolAdapter, uint256 receipts)
        external
        view
        override
        returns (uint256)
    {
        return IProtocolAdapter(protocolAdapter).getDepositTokenForReceipts(receipts);
    }

    // ============ Configuration ============

    /**
     * @notice Approve/revoke a protocol adapter
     * @param protocolAdapter Address of the adapter
     * @param approved Approval status
     */
    function approveProtocol(address protocolAdapter, bool approved) external override onlyOwnerOrAgent {
        BotVaultLib.botVaultStorage().approvedProtocols[protocolAdapter] = approved;
        emit ProtocolApprovalUpdated(protocolAdapter, approved);
    }

    /**
     * @notice Check if a protocol is approved
     */
    function isProtocolApproved(address protocolAdapter) external view override returns (bool) {
        return BotVaultLib.botVaultStorage().approvedProtocols[protocolAdapter];
    }
}
