// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title IBotVaultCore
 * @notice Core vault interface for bot-controlled ERC4626 vault
 */
interface IBotVaultCore is IERC4626 {
    // ============ Events ============
    event Deposited(address indexed user, uint256 assets, uint256 shares);
    event Withdrawn(address indexed user, uint256 assets, uint256 shares);
    event FeeCollected(address indexed recipient, uint256 amount);

    // ============ Errors ============
    error VaultPaused();
    error InvalidAmount();
    error InsufficientBalance();

    // ============ Core ERC4626 Functions ============

    /**
     * @notice Pause all vault operations
     */
    function pause() external;

    /**
     * @notice Unpause vault operations
     */
    function unpause() external;

    /**
     * @notice Check if vault is paused
     */
    function paused() external view returns (bool);

    /**
     * @notice Get total assets including deployed cross-chain
     * @dev Overrides ERC4626 totalAssets to include cross-chain deployments
     */
    function totalAssets() external view override returns (uint256);

    /**
     * @notice Set performance fee
     * @param fee Fee in basis points (max 2000 = 20%)
     */
    function setFee(uint96 fee) external;

    /**
     * @notice Get current fee
     */
    function getFee() external view returns (uint96);

    /**
     * @notice Initialize the vault
     */
    function initialize(bytes calldata data) external;
}
