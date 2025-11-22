// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title OptimismConfig
 * @notice Configuration constants for Optimism deployment
 * @dev Contains all addresses and parameters for ShareOFT deployment
 */
library OptimismConfig {
    // ============ LayerZero V2 Endpoint IDs ============

    uint32 internal constant ARBITRUM_EID = 30110; // Hub
    uint32 internal constant POLYGON_EID = 30109;
    uint32 internal constant OPTIMISM_EID = 30111;

    // ============ USDT Addresses ============

    /// @notice USDT on Optimism
    address internal constant USDT_OPTIMISM = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58;

    // ============ USDT OFT Adapters ============

    /// @notice USDT OFT Adapter on Optimism
    address internal constant USDT_OFT_OPTIMISM = 0xF03b4d9AC1D5d1E7c4cEf54C2A313b9fe051A0aD;

    // ============ LayerZero Endpoint ============

    /// @notice LayerZero V2 Endpoint
    address internal constant LAYERZERO_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
}
