// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IBotYield
 * @notice Interface for yield protocol integrations
 */
interface IBotYield {
    // ============ Events ============

    event DepositedToProtocol(
        address indexed protocolAdapter,
        address indexed token,
        uint256 amount,
        uint256 receipts
    );

    event WithdrawalRequested(address indexed protocolAdapter, uint256 receipts, bytes32 requestId);

    event WithdrawalFinalized(address indexed protocolAdapter, bytes32 requestId, uint256 amount);

    event RewardsHarvested(address indexed protocolAdapter, address[] tokens, uint256[] amounts);

    event ProtocolApprovalUpdated(address indexed protocolAdapter, bool approved);

    // ============ Errors ============

    error ProtocolNotApproved(address protocolAdapter);
    error ZeroAmount();
    error WithdrawalNotReady();

    // ============ Functions ============

    /**
     * @notice Deposit into a yield protocol
     * @param protocolAdapter Address of the protocol adapter (Aave, Compound, Pendle, etc.)
     * @param amount Amount to deposit
     * @param data Protocol-specific data
     * @return receipts Receipt tokens received
     */
    function depositToProtocol(address protocolAdapter, uint256 amount, bytes calldata data)
        external
        returns (uint256 receipts);

    /**
     * @notice Request withdrawal from protocol
     * @param protocolAdapter Address of the protocol adapter
     * @param receipts Amount of receipt tokens
     * @param data Protocol-specific data
     * @return requestId Withdrawal request ID
     */
    function requestWithdrawal(address protocolAdapter, uint256 receipts, bytes calldata data)
        external
        returns (bytes32 requestId);

    /**
     * @notice Finalize withdrawal
     * @param protocolAdapter Address of the protocol adapter
     * @param requestId Withdrawal request ID
     * @return amount Amount received
     */
    function finalizeWithdrawal(address protocolAdapter, bytes32 requestId) external returns (uint256 amount);

    /**
     * @notice Harvest protocol rewards
     * @param protocolAdapter Address of the protocol adapter
     * @return tokens Reward token addresses
     * @return amounts Reward amounts
     */
    function harvestRewards(address protocolAdapter)
        external
        returns (address[] memory tokens, uint256[] memory amounts);

    /**
     * @notice Get pending rewards
     */
    function getPendingRewards(address protocolAdapter) external view returns (uint256);

    /**
     * @notice Check if withdrawal is claimable
     */
    function isWithdrawalClaimable(address protocolAdapter, bytes32 requestId) external view returns (bool);

    /**
     * @notice Get protocol name
     */
    function getProtocolName(address protocolAdapter) external view returns (string memory);

    /**
     * @notice Preview withdrawal amount
     */
    function getWithdrawalAmount(address protocolAdapter, uint256 receipts) external view returns (uint256);

    /**
     * @notice Approve/revoke protocol
     */
    function approveProtocol(address protocolAdapter, bool approved) external;

    /**
     * @notice Check if protocol is approved
     */
    function isProtocolApproved(address protocolAdapter) external view returns (bool);
}
