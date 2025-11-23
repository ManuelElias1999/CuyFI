// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title IAToken
 * @notice Minimal interface for Aave V3 aTokens
 * @dev aTokens are interest-bearing tokens that represent deposits in Aave
 * Full interface: https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IAToken.sol
 */
interface IAToken is IERC20 {
    /**
     * @notice Returns the address of the underlying asset of this aToken (e.g. WETH for aWETH)
     * @return The address of the underlying asset
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice Returns the scaled balance of the user
     * @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The address of the user
     * @return The scaled balance of the user
     */
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @notice Returns the scaled total supply of the aToken
     * @dev The scaled total supply is the sum of all the updated stored balances divided by the reserve's liquidity index at the moment of the update
     * @return The scaled total supply
     */
    function scaledTotalSupply() external view returns (uint256);
}
