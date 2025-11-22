// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

/**
 * @title IBotStrategy
 * @notice Interface for cross-chain strategy deployment
 */
interface IBotStrategy {
    // ============ Events ============
    event DeployedToChain(
        bytes32 indexed deploymentId,
        uint32 indexed dstEid,
        address indexed dstVault,
        uint256 amount
    );
    event WithdrawnFromChain(bytes32 indexed deploymentId, uint256 amount);
    event DeploymentUpdated(bytes32 indexed deploymentId, uint256 oldAmount, uint256 newAmount);

    // ============ Errors ============
    error InvalidOFT();
    error InvalidVault();
    error DeploymentNotFound();
    error InsufficientDeployedAmount();

    // ============ Structs ============
    struct DeploymentInfo {
        uint32 dstEid;
        address dstVault;
        uint256 deployedAmount;
        uint256 lastUpdated;
    }

    // ============ Functions ============

    /**
     * @notice Deploy assets to another chain using LayerZero
     * @param dstEid Destination chain endpoint ID
     * @param amount The amount to deploy (USDT, 6 decimals)
     * @param sendParam LayerZero send parameters
     * @return deploymentId Unique identifier for this deployment
     */
    function deployToChain(
        uint32 dstEid,
        uint256 amount,
        SendParam memory sendParam
    ) external payable returns (bytes32 deploymentId);

    /**
     * @notice Withdraw assets from another chain
     * @param deploymentId The deployment to withdraw from
     * @param amount The amount to withdraw
     */
    function withdrawFromChain(bytes32 deploymentId, uint256 amount) external payable;

    /**
     * @notice Update deployment amount manually (called by bot)
     * @param deploymentId The deployment to update
     * @param newAmount The new amount (after yields/losses)
     */
    function updateDeploymentAmount(bytes32 deploymentId, uint256 newAmount) external;

    /**
     * @notice Get deployment info
     */
    function getDeployment(bytes32 deploymentId) external view returns (DeploymentInfo memory);

    /**
     * @notice Get all active deployments
     */
    function getActiveDeployments() external view returns (bytes32[] memory);

    /**
     * @notice Get total deployed on a specific chain
     */
    function getTotalDeployedOnChain(uint32 dstEid) external view returns (uint256);

    /**
     * @notice Quote the fee for deploying to a chain
     */
    function quoteDeployToChain(
        address from,
        address targetOft,
        uint256 amount,
        SendParam memory sendParam
    ) external view returns (MessagingFee memory);
}
