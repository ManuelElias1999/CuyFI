// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title PolygonSpokeConfig
 * @notice Configuration constants for Polygon Spoke deployment
 * @dev Contains all addresses and parameters for Spoke deployment
 */
library PolygonSpokeConfig {
    // ============ LayerZero V2 Endpoint IDs ============

    uint32 internal constant ARBITRUM_EID = 30110; // Hub
    uint32 internal constant POLYGON_EID = 30109; // Spoke

    // ============ USDT Addresses ============

    /// @notice USDT on Polygon
    address internal constant USDT_POLYGON = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    // ============ USDT OFT Adapters ============

    /// @notice USDT OFT Adapter on Polygon
    address internal constant USDT_OFT_POLYGON = 0x6BA10300f0DC58B7a1e4c0e41f5daBb7D7829e13;

    // ============ LayerZero Endpoint ============

    /// @notice LayerZero V2 Endpoint
    address internal constant LAYERZERO_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    // ============ Protocol Addresses (Polygon) ============

    /// @notice Aave V3 Pool on Polygon
    address internal constant AAVE_POOL_POLYGON = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    /// @notice Uniswap V3 Router on Polygon
    address internal constant UNISWAP_V3_ROUTER_POLYGON = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    /// @notice 1inch Aggregation Router V5 on Polygon
    address internal constant ONEINCH_ROUTER_POLYGON = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    // ============ Chainlink Price Feeds (Polygon) ============

    /// @notice USDT/USD price feed on Polygon
    address internal constant CHAINLINK_USDT_USD_POLYGON = 0x0A6513e40db6EB1b165753AD52E80663aeA50545;

    // ============ Default Parameters ============

    /// @notice Default performance fee (5% = 500 basis points)
    uint96 internal constant DEFAULT_FEE = 500;

    /// @notice Max performance fee (20% = 2000 basis points)
    uint96 internal constant MAX_FEE = 2000;

    /// @notice Fee denominator (100% = 10000 basis points)
    uint96 internal constant FEE_DENOMINATOR = 10000;
}
