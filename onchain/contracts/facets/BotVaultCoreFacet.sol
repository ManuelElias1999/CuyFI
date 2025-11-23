// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {BotVaultLib} from "../libraries/BotVaultLib.sol";
import {IBotVaultCore} from "../interfaces/IBotVaultCore.sol";

/**
 * @title BotVaultCoreFacet
 * @notice Core ERC4626 vault functionality for Diamond pattern
 * @dev Manual implementation without Upgradeable contracts
 */
contract BotVaultCoreFacet is IBotVaultCore {
    using Math for uint256;
    using SafeERC20 for IERC20;

    // Events are inherited from IERC20 and IERC4626

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

    modifier whenNotPaused() {
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
            string memory _name,
            string memory _symbol,
            address _asset,
            address _feeRecipient,
            uint96 _fee,
            address _owner,
            address _agent,
            address _composer
        ) = abi.decode(data, (string, string, address, address, uint96, address, address, address));

        if (_asset == address(0) || _feeRecipient == address(0) || _owner == address(0) || _agent == address(0)) {
            revert BotVaultLib.InvalidParameters();
        }

        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        if (ds.initialized) {
            revert BotVaultLib.InvalidParameters();
        }

        // Set ERC20 metadata
        ds.name = _name;
        ds.symbol = _symbol;
        ds.decimals = IERC20Metadata(_asset).decimals();

        // Set access control
        ds.owner = _owner;
        ds.agent = _agent;

        // Set fee config
        BotVaultLib.setFeeRecipient(_feeRecipient);
        BotVaultLib.setFee(_fee);

        // Set composer
        ds.composer = _composer;

        // Set asset
        ds.asset = _asset;

        // Mark as initialized
        ds.initialized = true;

        // Set supported interfaces
        ds.supportedInterfaces[type(IERC20).interfaceId] = true;
        ds.supportedInterfaces[type(IERC4626).interfaceId] = true;
    }

    // ============ ERC20 Functions ============

    function name() public view returns (string memory) {
        return BotVaultLib.botVaultStorage().name;
    }

    function symbol() public view returns (string memory) {
        return BotVaultLib.botVaultStorage().symbol;
    }

    function decimals() public view returns (uint8) {
        return BotVaultLib.botVaultStorage().decimals;
    }

    function totalSupply() public view returns (uint256) {
        return BotVaultLib.botVaultStorage().totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return BotVaultLib.botVaultStorage().balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return BotVaultLib.botVaultStorage().allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        uint256 currentAllowance = ds.allowances[from][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(from, msg.sender, currentAllowance - amount);
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    // ============ ERC4626 Functions ============

    function asset() public view returns (address) {
        return BotVaultLib.botVaultStorage().asset;
    }

    function totalAssets() public view override returns (uint256) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        uint256 localBalance = IERC20(ds.asset).balanceOf(address(this));
        uint256 deployedAmount = BotVaultLib.getTotalDeployed();
        return localBalance + deployedAmount;
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    function maxDeposit(address) public view returns (uint256) {
        return BotVaultLib.botVaultStorage().paused ? 0 : type(uint256).max;
    }

    function maxMint(address) public view returns (uint256) {
        return BotVaultLib.botVaultStorage().paused ? 0 : type(uint256).max;
    }

    function maxWithdraw(address owner) public view returns (uint256) {
        return BotVaultLib.botVaultStorage().paused ? 0 : _convertToAssets(balanceOf(owner), Math.Rounding.Floor);
    }

    function maxRedeem(address owner) public view returns (uint256) {
        return BotVaultLib.botVaultStorage().paused ? 0 : balanceOf(owner);
    }

    function previewDeposit(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    function previewMint(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Ceil);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Ceil);
    }

    function previewRedeem(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    function deposit(uint256 assets, address receiver) public override whenNotPaused returns (uint256 shares) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        shares = previewDeposit(assets);
        _deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver) public override whenNotPaused returns (uint256 assets) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        assets = previewMint(shares);
        _deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner)
        public
        override
        whenNotPaused
        returns (uint256 shares)
    {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        shares = previewWithdraw(assets);
        _withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        whenNotPaused
        returns (uint256 assets)
    {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        assets = previewRedeem(shares);
        _withdraw(msg.sender, receiver, owner, assets, shares);
    }

    // ============ Pause Functions ============

    function pause() external override onlyOwnerOrAgent {
        BotVaultLib.botVaultStorage().paused = true;
    }

    function unpause() external override onlyOwner {
        BotVaultLib.botVaultStorage().paused = false;
    }

    function paused() public view override returns (bool) {
        return BotVaultLib.botVaultStorage().paused;
    }

    // ============ Fee Management ============

    function setFee(uint96 fee) external override onlyOwner {
        BotVaultLib.setFee(fee);
    }

    function getFee() external view override returns (uint96) {
        return BotVaultLib.botVaultStorage().fee;
    }

    // ============ Composer Management ============

    function setComposer(address _composer) external onlyOwner {
        BotVaultLib.botVaultStorage().composer = _composer;
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

    // ============ Internal Functions ============

    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view returns (uint256) {
        uint256 supply = totalSupply();
        return (assets == 0 || supply == 0) ? assets : assets.mulDiv(supply, totalAssets(), rounding);
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view returns (uint256) {
        uint256 supply = totalSupply();
        return (supply == 0) ? shares : shares.mulDiv(totalAssets(), supply, rounding);
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        // Transfer assets from caller
        IERC20(ds.asset).safeTransferFrom(caller, address(this), assets);

        // Mint shares to receiver
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
        emit Deposited(receiver, assets, shares);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        if (caller != owner) {
            uint256 currentAllowance = ds.allowances[owner][caller];
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= shares, "ERC4626: insufficient allowance");
                unchecked {
                    _approve(owner, caller, currentAllowance - shares);
                }
            }
        }

        // Burn shares from owner
        _burn(owner, shares);

        // Transfer assets to receiver
        IERC20(ds.asset).safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
        emit Withdrawn(receiver, assets, shares);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");

        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        uint256 fromBalance = ds.balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            ds.balances[from] = fromBalance - amount;
            ds.balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to zero address");

        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        ds.totalSupply += amount;
        unchecked {
            ds.balances[account] += amount;
        }

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from zero address");

        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        uint256 accountBalance = ds.balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            ds.balances[account] = accountBalance - amount;
            ds.totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");

        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        ds.allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
}

// Helper interface for getting decimals
interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}
