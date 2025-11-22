// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title ArbitrumHubConfig
 * @notice Configuration constants for Arbitrum Hub deployment
 * @dev Contains all addresses and parameters for Hub & Spoke architecture
 */
library ArbitrumHubConfig {
    // ============ LayerZero V2 Endpoint IDs ============

    uint32 internal constant ARBITRUM_EID = 30110; // Hub
    uint32 internal constant POLYGON_EID = 30109; // Spoke
    uint32 internal constant ETHEREUM_EID = 30101; // Spoke
    uint32 internal constant OPTIMISM_EID = 30111; // Spoke

    // ============ USDT Addresses ============

    /// @notice USDT on Arbitrum (hub asset)
    address internal constant USDT_ARBITRUM = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    /// @notice USDT on Polygon
    address internal constant USDT_POLYGON = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    /// @notice USDT on Ethereum
    address internal constant USDT_ETHEREUM = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// @notice USDT on Optimism
    address internal constant USDT_OPTIMISM = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58;

    // ============ USDT OFT Adapters ============

    /// @notice USDT OFT Adapter on Arbitrum (hub)
    address internal constant USDT_OFT_ARBITRUM = 0x14E4A1B13bf7F943c8ff7C51fb60FA964A298D92;

    /// @notice USDT OFT Adapter on Polygon
    address internal constant USDT_OFT_POLYGON = 0x6BA10300f0DC58B7a1e4c0e41f5daBb7D7829e13;

    /// @notice USDT OFT Adapter on Ethereum
    address internal constant USDT_OFT_ETHEREUM = 0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee;

    /// @notice USDT OFT Adapter on Optimism
    address internal constant USDT_OFT_OPTIMISM = 0xF03b4d9AC1D5d1E7c4cEf54C2A313b9fe051A0aD;

    // ============ LayerZero Endpoint ============

    /// @notice LayerZero V2 Endpoint (same on all chains)
    address internal constant LAYERZERO_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    // ============ Protocol Addresses (Arbitrum) ============

    /// @notice Pendle Router on Arbitrum
    address internal constant PENDLE_ROUTER_ARBITRUM = 0x00000000005BBB0EF59571E58418F9a4357b68A0;

    /// @notice Aave V3 Pool on Arbitrum
    address internal constant AAVE_POOL_ARBITRUM = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    /// @notice Uniswap V3 Router on Arbitrum
    address internal constant UNISWAP_V3_ROUTER_ARBITRUM = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    /// @notice 1inch Aggregation Router V5 on Arbitrum
    address internal constant ONEINCH_ROUTER_ARBITRUM = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    // ============ Chainlink Price Feeds (Arbitrum) ============

    /// @notice USDT/USD price feed on Arbitrum
    address internal constant CHAINLINK_USDT_USD_ARBITRUM = 0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7;

    // ============ Default Parameters ============

    /// @notice Default performance fee (5% = 500 basis points)
    uint96 internal constant DEFAULT_FEE = 500;

    /// @notice Max performance fee (20% = 2000 basis points)
    uint96 internal constant MAX_FEE = 2000;

    /// @notice Fee denominator (100% = 10000 basis points)
    uint96 internal constant FEE_DENOMINATOR = 10000;

    // ============ Helper Functions ============

    /**
     * @notice Get OFT adapter address for a given chain
     * @param eid LayerZero endpoint ID
     * @return OFT adapter address
     */
    function getOFTForChain(uint32 eid) internal pure returns (address) {
        if (eid == ARBITRUM_EID) return USDT_OFT_ARBITRUM;
        if (eid == POLYGON_EID) return USDT_OFT_POLYGON;
        if (eid == ETHEREUM_EID) return USDT_OFT_ETHEREUM;
        if (eid == OPTIMISM_EID) return USDT_OFT_OPTIMISM;
        revert("Invalid EID");
    }

    /**
     * @notice Get USDT address for a given chain
     * @param eid LayerZero endpoint ID
     * @return USDT token address
     */
    function getUSDTForChain(uint32 eid) internal pure returns (address) {
        if (eid == ARBITRUM_EID) return USDT_ARBITRUM;
        if (eid == POLYGON_EID) return USDT_POLYGON;
        if (eid == ETHEREUM_EID) return USDT_ETHEREUM;
        if (eid == OPTIMISM_EID) return USDT_OPTIMISM;
        revert("Invalid EID");
    }

    /**
     * @notice Get chain name for a given EID
     * @param eid LayerZero endpoint ID
     * @return Chain name
     */
    function getChainName(uint32 eid) internal pure returns (string memory) {
        if (eid == ARBITRUM_EID) return "Arbitrum";
        if (eid == POLYGON_EID) return "Polygon";
        if (eid == ETHEREUM_EID) return "Ethereum";
        if (eid == OPTIMISM_EID) return "Optimism";
        return "Unknown";
    }

    /**
     * @notice Check if EID is a valid spoke chain
     * @param eid LayerZero endpoint ID
     * @return True if valid spoke
     */
    function isValidSpoke(uint32 eid) internal pure returns (bool) {
        return eid == POLYGON_EID || eid == ETHEREUM_EID || eid == OPTIMISM_EID;
    }

    /**
     * @notice Check if EID is the hub
     * @param eid LayerZero endpoint ID
     * @return True if hub
     */
    function isHub(uint32 eid) internal pure returns (bool) {
        return eid == ARBITRUM_EID;
    }
}
