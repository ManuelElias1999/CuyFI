// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IAggregatorV2V3Interface} from "../interfaces/Chainlink/IAggregatorV2V3Interface.sol";

/**
 * @title ChainlinkOracleHelper
 * @notice Simplified Chainlink oracle helper (based on OracleRegistry)
 * @dev Provides price feeds for asset valuation
 */
library ChainlinkOracleHelper {
    error OraclePriceIsOld();
    error OraclePriceIsNegative();
    error OracleNotSet();

    /**
     * @notice Oracle configuration for an asset
     * @param aggregator Chainlink aggregator interface
     * @param stalenessThreshold Maximum allowed staleness in seconds
     */
    struct OracleInfo {
        IAggregatorV2V3Interface aggregator;
        uint96 stalenessThreshold;
    }

    /**
     * @notice Get latest price from Chainlink oracle
     * @param info Oracle configuration
     * @return price Latest price
     */
    function getPrice(OracleInfo memory info) internal view returns (uint256 price) {
        if (address(info.aggregator) == address(0)) revert OracleNotSet();

        // Get latest round data
        (, int256 answer, , uint256 updatedAt,) = info.aggregator.latestRoundData();

        // Check price is not negative
        if (answer <= 0) revert OraclePriceIsNegative();

        // Check price is not stale
        if (block.timestamp - updatedAt > info.stalenessThreshold) {
            revert OraclePriceIsOld();
        }

        return uint256(answer);
    }

    /**
     * @notice Get price with safe fallback
     * @param info Oracle configuration
     * @return price Latest price
     * @return success Whether price was successfully retrieved
     */
    function getPriceSafe(OracleInfo memory info) internal view returns (uint256 price, bool success) {
        if (address(info.aggregator) == address(0)) return (0, false);

        try info.aggregator.latestRoundData() returns (
            uint80, int256 answer, uint256, uint256 updatedAt, uint80
        ) {
            if (answer <= 0) return (0, false);
            if (block.timestamp - updatedAt > info.stalenessThreshold) return (0, false);

            return (uint256(answer), true);
        } catch {
            return (0, false);
        }
    }

    /**
     * @notice Convert amount from one token to another using oracles
     * @param fromInfo Oracle for source token
     * @param toInfo Oracle for destination token
     * @param amount Amount in source token
     * @return converted Amount in destination token
     */
    function convertPrice(OracleInfo memory fromInfo, OracleInfo memory toInfo, uint256 amount)
        internal
        view
        returns (uint256 converted)
    {
        uint256 fromPrice = getPrice(fromInfo);
        uint256 toPrice = getPrice(toInfo);

        // Convert: amount * fromPrice / toPrice
        return (amount * fromPrice) / toPrice;
    }

    /**
     * @notice Get USD value of an amount
     * @param info Oracle for the token (must be USD-denominated)
     * @param amount Amount of tokens
     * @param decimals Token decimals
     * @return usdValue Value in USD (8 decimals, matching Chainlink)
     */
    function getUSDValue(OracleInfo memory info, uint256 amount, uint8 decimals)
        internal
        view
        returns (uint256 usdValue)
    {
        uint256 price = getPrice(info); // Price in USD (8 decimals from Chainlink)
        uint8 oracleDecimals = info.aggregator.decimals();

        // Normalize to 8 decimals
        if (oracleDecimals > 8) {
            price = price / (10 ** (oracleDecimals - 8));
        } else if (oracleDecimals < 8) {
            price = price * (10 ** (8 - oracleDecimals));
        }

        // Calculate USD value
        // value = amount * price / (10 ** decimals)
        return (amount * price) / (10 ** decimals);
    }
}
