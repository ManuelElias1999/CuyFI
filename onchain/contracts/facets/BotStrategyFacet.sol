// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {BotVaultLib} from "../libraries/BotVaultLib.sol";
import {IBotStrategy} from "../interfaces/IBotStrategy.sol";
import {SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {IOFT} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

interface IBotVaultComposer {
    function depositAndSend(
        uint256 amount,
        SendParam memory sendParam,
        address refundAddress
    ) external payable;
}

/**
 * @title BotStrategyFacet
 * @notice Cross-chain strategy deployment using LayerZero on Hub & Spoke architecture
 * @dev Uses BotVaultComposer for cross-chain transfers, manual tracking (no oracles)
 *
 * Hub & Spoke:
 * - Hub: Arbitrum (EID 30110) - Main vault
 * - Spokes: Polygon (30109), Ethereum (30101), Optimism (30111)
 *
 * Agent can deploy USDT from hub to any spoke for yield farming
 */
contract BotStrategyFacet is IBotStrategy, ReentrancyGuard {
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

    // ============ Cross-Chain Deployment ============

    /**
     * @notice Deploy assets to another chain via LayerZero
     * @dev Agent-only function to deploy USDT to approved destinations
     * @param dstEid Destination chain endpoint ID (e.g., 30109 for Polygon)
     * @param amount Amount of USDT to deploy (6 decimals)
     * @param sendParam LayerZero parameters (destination, options, etc.)
     * @return deploymentId Unique ID for tracking this deployment
     */
    function deployToChain(
        uint32 dstEid,
        uint256 amount,
        SendParam memory sendParam
    ) external payable override onlyAgent nonReentrant returns (bytes32 deploymentId) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        // Validations
        if (amount == 0) revert BotVaultLib.InvalidParameters();

        // Get USDT OFT for destination chain
        address oftAddress = _getOFTForChain(dstEid);
        if (!ds.approvedOFTs[oftAddress]) revert InvalidOFT();

        // Get composer
        IBotVaultComposer composer = IBotVaultComposer(ds.composer);

        // Approve composer to spend USDT OFT
        IERC20(oftAddress).forceApprove(address(composer), amount);

        // Deploy via composer
        composer.depositAndSend{value: msg.value}(
            amount,
            sendParam,
            msg.sender // refund address
        );

        // Reset approval
        IERC20(oftAddress).forceApprove(address(composer), 0);

        // Record deployment (simplified tracking, no oracles)
        address dstVault = _bytes32ToAddress(sendParam.to);
        deploymentId = BotVaultLib.recordDeployment(sendParam.dstEid, dstVault, amount);

        emit DeployedToChain(deploymentId, sendParam.dstEid, dstVault, amount);
    }

    /**
     * @notice Withdraw from a cross-chain deployment
     * @dev This would trigger a cross-chain redeem operation
     * @param deploymentId The deployment to withdraw from
     * @param amount Amount to withdraw
     */
    function withdrawFromChain(bytes32 deploymentId, uint256 amount)
        external
        payable
        override
        onlyAgent
        nonReentrant
    {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        BotVaultLib.CrossChainDeployment storage deployment = ds.deployments[deploymentId];

        if (deployment.deployedAmount == 0) revert DeploymentNotFound();
        if (amount > deployment.deployedAmount) revert InsufficientDeployedAmount();

        // Update tracking
        uint256 newAmount = deployment.deployedAmount - amount;
        BotVaultLib.updateDeployment(deploymentId, newAmount);

        // If fully withdrawn, remove deployment
        if (newAmount == 0) {
            BotVaultLib.removeDeployment(deploymentId);
        }

        emit WithdrawnFromChain(deploymentId, amount);

        // Note: Actual cross-chain withdrawal would need to be handled separately
        // via LayerZero message to the destination vault
        // For simplicity, we assume the agent handles the actual withdrawal
        // and this function just updates the tracking
    }

    /**
     * @notice Update deployment amount (when yields accrue or losses occur)
     * @dev Agent calls this after checking actual balance on destination chain
     * @param deploymentId The deployment to update
     * @param newAmount The new total amount (including yields/losses)
     */
    function updateDeploymentAmount(bytes32 deploymentId, uint256 newAmount)
        external
        override
        onlyAgent
    {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        BotVaultLib.CrossChainDeployment storage deployment = ds.deployments[deploymentId];

        if (deployment.deployedAmount == 0) revert DeploymentNotFound();

        uint256 oldAmount = deployment.deployedAmount;
        BotVaultLib.updateDeployment(deploymentId, newAmount);

        emit DeploymentUpdated(deploymentId, oldAmount, newAmount);
    }

    // ============ View Functions ============

    function getDeployment(bytes32 deploymentId)
        external
        view
        override
        returns (DeploymentInfo memory)
    {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        BotVaultLib.CrossChainDeployment storage deployment = ds.deployments[deploymentId];

        return DeploymentInfo({
            dstEid: deployment.dstEid,
            dstVault: deployment.dstVault,
            deployedAmount: deployment.deployedAmount,
            lastUpdated: deployment.lastUpdated
        });
    }

    function getActiveDeployments() external view override returns (bytes32[] memory) {
        return BotVaultLib.botVaultStorage().activeDeployments;
    }

    function getTotalDeployedOnChain(uint32 dstEid) external view override returns (uint256) {
        return BotVaultLib.botVaultStorage().totalDeployedByChain[dstEid];
    }

    function quoteDeployToChain(
        address, /* from */
        address targetOft,
        uint256, /* amount */
        SendParam memory sendParam
    ) external view override returns (MessagingFee memory) {
        // Quote using the IOFT interface directly
        return IOFT(targetOft).quoteSend(sendParam, false);
    }

    // ============ Configuration ============

    function approveOFT(address oft, bool approved) external onlyOwnerOrAgent {
        BotVaultLib.botVaultStorage().approvedOFTs[oft] = approved;
    }

    function isOFTApproved(address oft) external view returns (bool) {
        return BotVaultLib.botVaultStorage().approvedOFTs[oft];
    }

    // ============ Internal Helpers ============

    function _bytes32ToAddress(bytes32 _b) internal pure returns (address) {
        return address(uint160(uint256(_b)));
    }

    /**
     * @notice Get the USDT OFT adapter address for a given chain
     * @param dstEid Destination chain endpoint ID
     * @return OFT adapter address for that chain
     */
    function _getOFTForChain(uint32 dstEid) internal pure returns (address) {
        // Hardcoded OFT addresses for each chain (checksummed)
        if (dstEid == 30109) return 0x6BA10300f0DC58B7a1e4c0e41f5daBb7D7829e13; // Polygon
        if (dstEid == 30101) return 0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee; // Ethereum
        if (dstEid == 30111) return 0xF03b4d9AC1D5d1E7c4cEf54C2A313b9fe051A0aD; // Optimism
        if (dstEid == 30110) return 0x14E4A1B13bf7F943c8ff7C51fb60FA964A298D92; // Arbitrum

        revert("Invalid destination EID");
    }
}
