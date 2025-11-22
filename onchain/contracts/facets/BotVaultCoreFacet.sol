// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {BotVaultLib} from "../libraries/BotVaultLib.sol";
import {IBotVaultCore} from "../interfaces/IBotVaultCore.sol";

/**
 * @title BotVaultCoreFacet
 * @notice Core ERC4626 vault functionality (simplified from VaultFacet)
 * @dev Handles deposits, withdrawals, and share accounting
 */
contract BotVaultCoreFacet is ERC4626Upgradeable, PausableUpgradeable, IBotVaultCore {
    using Math for uint256;
    using SafeERC20 for IERC20;

    // ============ Modifiers ============

    modifier onlyOwner() {
        BotVaultLib.enforceIsOwner();
        _;
    }

    modifier onlyAgent() {
        BotVaultLib.enforceIsAgent();
        _;
    }

    modifier onlyOwnerOrAgent() {
        BotVaultLib.enforceIsOwnerOrAgent();
        _;
    }

    // Custom pause check using our storage
    modifier whenVaultNotPaused() {
        if (BotVaultLib.botVaultStorage().paused) revert VaultPaused();
        _;
    }

    // ============ Initialization ============

    /**
     * @notice Initialize the vault
     * @param data Encoded initialization data (name, symbol, asset, feeRecipient, fee, owner, agent, composer)
     */
    function initialize(bytes calldata data) external override {
        (
            string memory name,
            string memory symbol,
            address asset,
            address feeRecipient,
            uint96 fee,
            address owner,
            address agent,
            address composer
        ) = abi.decode(data, (string, string, address, address, uint96, address, address, address));

        if (asset == address(0) || feeRecipient == address(0) || owner == address(0) || agent == address(0)) {
            revert BotVaultLib.InvalidParameters();
        }

        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        // Set access control
        ds.owner = owner;
        ds.agent = agent;

        // Set fee config
        BotVaultLib.setFeeRecipient(feeRecipient);
        BotVaultLib.setFee(fee);

        // Set composer
        ds.composer = composer;

        // Initialize ERC4626
        __ERC4626_init(IERC20(asset));
        __ERC20_init(name, symbol);
        __Pausable_init();

        ds.asset = asset;

        // Set supported interfaces
        ds.supportedInterfaces[type(IERC20).interfaceId] = true;
        ds.supportedInterfaces[type(IBotVaultCore).interfaceId] = true;
    }

    // ============ Pause Functions ============

    function pause() external override onlyOwnerOrAgent {
        BotVaultLib.botVaultStorage().paused = true;
        _pause();
    }

    function unpause() external override onlyOwner {
        BotVaultLib.botVaultStorage().paused = false;
        _unpause();
    }

    function paused() public view override(PausableUpgradeable, IBotVaultCore) returns (bool) {
        return BotVaultLib.botVaultStorage().paused;
    }

    // ============ ERC4626 Core (Overrides) ============

    /**
     * @notice Total assets including deployed cross-chain
     * @dev Overrides ERC4626 to include cross-chain deployments
     */
    function totalAssets() public view override(ERC4626Upgradeable, IBotVaultCore) returns (uint256) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        // Local balance
        uint256 localBalance = IERC20(ds.asset).balanceOf(address(this));

        // Add cross-chain deployments (simplified tracking)
        uint256 deployedAmount = BotVaultLib.getTotalDeployed();

        return localBalance + deployedAmount;
    }

    /**
     * @notice Deposit assets and receive shares
     * @dev Standard ERC4626 deposit with pause check
     */
    function deposit(uint256 assets, address receiver)
        public
        override(ERC4626Upgradeable, IERC4626)
        whenVaultNotPaused
        returns (uint256 shares)
    {
        shares = super.deposit(assets, receiver);
        emit Deposited(msg.sender, assets, shares);
    }

    /**
     * @notice Mint shares by depositing assets
     * @dev Standard ERC4626 mint with pause check
     */
    function mint(uint256 shares, address receiver)
        public
        override(ERC4626Upgradeable, IERC4626)
        whenVaultNotPaused
        returns (uint256 assets)
    {
        assets = super.mint(shares, receiver);
        emit Deposited(msg.sender, assets, shares);
    }

    /**
     * @notice Withdraw assets by burning shares
     * @dev Standard ERC4626 withdraw with pause check
     */
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override(ERC4626Upgradeable, IERC4626)
        whenVaultNotPaused
        returns (uint256 shares)
    {
        shares = super.withdraw(assets, receiver, owner);
        emit Withdrawn(msg.sender, assets, shares);
    }

    /**
     * @notice Redeem shares for assets
     * @dev Standard ERC4626 redeem with pause check
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        override(ERC4626Upgradeable, IERC4626)
        whenVaultNotPaused
        returns (uint256 assets)
    {
        assets = super.redeem(shares, receiver, owner);
        emit Withdrawn(msg.sender, assets, shares);
    }

    // ============ Fee Management ============

    function setFee(uint96 fee) external override onlyOwner {
        BotVaultLib.setFee(fee);
    }

    function getFee() external view override returns (uint96) {
        return BotVaultLib.botVaultStorage().fee;
    }

    // ============ View Functions ============

    function getOwner() external view returns (address) {
        return BotVaultLib.botVaultStorage().owner;
    }

    function getAgent() external view returns (address) {
        return BotVaultLib.botVaultStorage().agent;
    }

    function getComposer() external view returns (address) {
        return BotVaultLib.botVaultStorage().composer;
    }

    function getFeeRecipient() external view returns (address) {
        return BotVaultLib.botVaultStorage().feeRecipient;
    }
}
