// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";
import {IPool} from "../interfaces/external/aave/IPool.sol";
import {IAToken} from "../interfaces/external/aave/IAToken.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title AaveAdapter
 * @notice Adapter for Aave V3 Protocol yield farming
 * @dev Supports USDT deposits on Polygon (or any Aave V3 compatible chain)
 *
 * Key Aave V3 contracts on Polygon:
 * - Pool: 0x794a61358D6845594F94dc1DB02A252b5b4814aD
 * - USDT aToken: Get via Pool.getReserveData(USDT).aTokenAddress
 *
 * Flow:
 * 1. Stake: USDT → Aave Pool.supply() → receive aUSDT (auto-compounds)
 * 2. Unstake: Aave Pool.withdraw(aUSDT amount) → receive USDT
 *
 * Note: Aave is 1-step withdrawal (no request/finalize needed)
 */
contract AaveAdapter is IProtocolAdapter {
    using SafeERC20 for IERC20;

    // ============ Immutables ============

    /// @notice The token accepted for deposits (e.g., USDT on Polygon)
    address public immutable depositToken;

    /// @notice The receipt token (aToken - e.g., aUSDT)
    address public immutable receiptToken;

    /// @notice Aave V3 Pool address
    IPool public immutable pool;

    // ============ Errors ============

    error InvalidAToken();
    error InvalidPool();
    error WithdrawalNotSupported(); // Aave doesn't use 2-step withdrawals

    // ============ Constructor ============

    /**
     * @notice Initialize the Aave adapter
     * @param _depositToken The token to accept (e.g., USDT on Polygon)
     * @param _pool The Aave V3 Pool address
     * @dev Automatically fetches the aToken address from the pool
     *
     * Example for Polygon USDT:
     * - depositToken: 0xc2132D05D31c914a87C6611C10748AEb04B58e8F (USDT)
     * - pool: 0x794a61358D6845594F94dc1DB02A252b5b4814aD
     */
    constructor(address _depositToken, address _pool) {
        if (_pool == address(0)) revert InvalidPool();

        depositToken = _depositToken;
        pool = IPool(_pool);

        // Get aToken address from Aave Pool
        (,,,,,,,, address aTokenAddress,,,,,,) = pool.getReserveData(_depositToken);

        if (aTokenAddress == address(0)) revert InvalidAToken();

        receiptToken = aTokenAddress;

        // Verify aToken's underlying matches our deposit token
        require(
            IAToken(aTokenAddress).UNDERLYING_ASSET_ADDRESS() == _depositToken,
            "AToken underlying mismatch"
        );
    }

    // ============ Staking Functions ============

    /**
     * @notice Stake deposit tokens into Aave (USDT → aUSDT)
     * @param amount Amount of deposit token to stake
     * @return receipts Amount of aTokens received (1:1 ratio initially, grows with yield)
     * @dev Flow: depositToken → Aave Pool.supply() → aToken
     *
     * Aave auto-compounds yields by increasing aToken balance via rebasing
     */
    function stake(uint256 amount, bytes calldata) public returns (uint256 receipts) {
        // Transfer deposit token from vault to adapter
        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), amount);

        // Get aToken balance before
        uint256 aTokenBefore = IERC20(receiptToken).balanceOf(msg.sender);

        // Approve Aave Pool
        IERC20(depositToken).forceApprove(address(pool), amount);

        // Supply to Aave (aTokens minted directly to msg.sender - the vault)
        pool.supply(depositToken, amount, msg.sender, 0); // referralCode = 0

        // Get aToken balance after
        uint256 aTokenAfter = IERC20(receiptToken).balanceOf(msg.sender);

        // Calculate receipts (should be approximately equal to amount)
        receipts = aTokenAfter - aTokenBefore;

        // Reset approval
        IERC20(depositToken).forceApprove(address(pool), 0);

        return receipts;
    }

    // ============ Unstaking Functions ============

    /**
     * @notice Request unstaking from Aave (not needed - Aave is instant withdrawal)
     * @dev Aave doesn't require 2-step withdrawal, so this reverts
     * Use the `withdraw()` function directly for instant withdrawals
     */
    function requestUnstake(uint256, bytes calldata) external pure returns (bytes32) {
        revert WithdrawalNotSupported();
    }

    /**
     * @notice Finalize unstaking (not needed - Aave is instant withdrawal)
     * @dev Aave doesn't require 2-step withdrawal, so this reverts
     * Use the `withdraw()` function directly for instant withdrawals
     */
    function finalizeUnstake(bytes32) external pure returns (uint256) {
        revert WithdrawalNotSupported();
    }

    /**
     * @notice Withdraw from Aave (instant - no request needed)
     * @param shares Amount of aTokens to withdraw
     * @return amount Amount of deposit tokens returned
     * @dev Flow: aToken → Aave Pool.withdraw() → depositToken
     *
     * Note: Due to yield accrual, you'll receive more USDT than you deposited
     */
    function withdraw(uint256 shares) external returns (uint256 amount) {
        // Transfer aTokens from sender to adapter
        IERC20(receiptToken).safeTransferFrom(msg.sender, address(this), shares);

        // Withdraw from Aave (sends USDT directly to msg.sender - the vault)
        amount = pool.withdraw(depositToken, shares, msg.sender);

        return amount;
    }

    // ============ Rewards & Harvesting ============

    /**
     * @notice Harvest rewards from Aave
     * @return tokens Array of reward token addresses
     * @return amounts Array of reward amounts
     * @dev Aave V3 auto-compounds yields into aToken balance (no separate rewards)
     *      Yields are realized when you withdraw and get more USDT than deposited
     */
    function harvest() external pure returns (address[] memory tokens, uint256[] memory amounts) {
        tokens = new address[](0);
        amounts = new uint256[](0);
        return (tokens, amounts);
    }

    /**
     * @notice Get pending rewards (if any)
     * @return Pending reward amount
     * @dev Returns 0 as Aave auto-compounds yields into aToken balance
     */
    function getPendingRewards() external pure returns (uint256) {
        return 0;
    }

    // ============ View Functions ============

    /**
     * @notice Preview how many deposit tokens you'd get for redeeming aTokens
     * @param receiptAmount Amount of aTokens
     * @return Estimated deposit token amount (includes accrued yield)
     * @dev Due to yield accrual, 1 aUSDT > 1 USDT over time
     *      This is calculated via the reserve's liquidity index
     */
    function getDepositTokenForReceipts(uint256 receiptAmount) public view returns (uint256) {
        // For Aave, aToken balance already represents the underlying value
        // The aToken is rebasing, so 1 aUSDT ≈ 1 USDT + accrued yield

        // We can calculate exact value using normalized income
        uint256 normalizedIncome = pool.getReserveNormalizedIncome(depositToken);

        // Convert scaled balance to actual balance
        // actualBalance = scaledBalance * normalizedIncome / 1e27
        uint256 scaledAmount = (receiptAmount * 1e27) / normalizedIncome;

        // Return the actual underlying value (which includes yield)
        return (scaledAmount * normalizedIncome) / 1e27;
    }

    /**
     * @notice Check if a withdrawal request is ready to claim
     * @param requestId The request ID
     * @return Always returns false (Aave doesn't use request/finalize pattern)
     */
    function isWithdrawalClaimable(bytes32 requestId) external pure returns (bool) {
        return false; // Aave doesn't use 2-step withdrawals
    }

    /**
     * @notice Get the protocol name
     * @return Protocol identifier
     */
    function getProtocolName() external pure returns (string memory) {
        return "Aave V3";
    }

    // ============ IProtocolAdapter Implementation ============

    /**
     * @notice Deposit asset into protocol (IProtocolAdapter interface)
     * @param asset Asset to deposit (must match depositToken)
     * @param amount Amount to deposit
     * @return shares Amount of aTokens received
     */
    function deposit(address asset, uint256 amount) external returns (uint256 shares) {
        require(asset == depositToken, "Invalid asset");
        return this.stake(amount, new bytes(0));
    }

    /**
     * @notice Get total value in protocol (IProtocolAdapter interface)
     * @return Total value in deposit token terms
     */
    function totalValue() external view returns (uint256) {
        uint256 aTokenBalance = IERC20(receiptToken).balanceOf(address(this));
        if (aTokenBalance == 0) return 0;

        return getDepositTokenForReceipts(aTokenBalance);
    }
}
