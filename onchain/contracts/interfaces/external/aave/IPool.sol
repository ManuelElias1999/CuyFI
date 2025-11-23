// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPool
 * @notice Minimal interface for Aave V3 Pool
 * @dev Based on Aave V3 Pool contract
 * Full interface: https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPool.sol
 */
interface IPool {
    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user wants to receive them on his own wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards. 0 if the action is executed directly by the user, without any middle-man
     */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn. Use type(uint256).max to withdraw the entire balance
     * @param to The address that will receive the underlying, same as msg.sender if the user wants to receive it on his own wallet
     * @return The final amount withdrawn
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Returns the normalized income of the reserve
     * @param asset The address of the underlying asset
     * @return The reserve's normalized income (in ray units - 27 decimals)
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return configuration The configuration of the reserve
     * @return liquidityIndex The liquidity index of the reserve
     * @return currentLiquidityRate The current liquidity rate of the reserve
     * @return variableBorrowIndex The variable borrow index of the reserve
     * @return currentVariableBorrowRate The current variable borrow rate of the reserve
     * @return currentStableBorrowRate The current stable borrow rate of the reserve
     * @return lastUpdateTimestamp The timestamp of the last update of the reserve
     * @return id The id of the reserve
     * @return aTokenAddress The address of the aToken
     * @return stableDebtTokenAddress The address of the stable debt token
     * @return variableDebtTokenAddress The address of the variable debt token
     * @return interestRateStrategyAddress The address of the interest rate strategy
     * @return accruedToTreasury The amount accrued to treasury
     * @return unbacked The unbacked amount
     * @return isolationModeTotalDebt The total debt in isolation mode
     */
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 configuration,
            uint128 liquidityIndex,
            uint128 currentLiquidityRate,
            uint128 variableBorrowIndex,
            uint128 currentVariableBorrowRate,
            uint128 currentStableBorrowRate,
            uint40 lastUpdateTimestamp,
            uint16 id,
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress,
            address interestRateStrategyAddress,
            uint128 accruedToTreasury,
            uint128 unbacked,
            uint128 isolationModeTotalDebt
        );
}
