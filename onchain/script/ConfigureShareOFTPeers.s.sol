// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BotVaultShareOFT} from "../contracts/BotVaultShareOFT.sol";
import {BotVaultShareOFT_Spoke} from "../contracts/BotVaultShareOFT_Spoke.sol";

/**
 * @title ConfigureShareOFTPeers
 * @notice Script to configure LayerZero peers for ShareOFT across chains
 *
 * Deployment Addresses:
 * - Arbitrum (30110): 0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE (Hub OFT)
 * - Polygon (30109):  0x0f6001507Dd8B6eAec1a63AC782DE18538bD1d15 (Spoke OFT)
 * - Optimism (30111): 0x20D98107660c12331d344dFE90E573765eF004cf (Spoke OFT)
 *
 * Peer Configuration:
 * Each chain needs to know about the others using LayerZero EIDs
 */
contract ConfigureShareOFTPeers is Script {
    // LayerZero Endpoint IDs
    uint32 constant ARBITRUM_EID = 30110;
    uint32 constant POLYGON_EID = 30109;
    uint32 constant OPTIMISM_EID = 30111;

    // ShareOFT Addresses
    address constant ARBITRUM_SHAREOFT = 0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE;
    address constant POLYGON_SHAREOFT = 0x0f6001507Dd8B6eAec1a63AC782DE18538bD1d15;
    address constant OPTIMISM_SHAREOFT = 0x20D98107660c12331d344dFE90E573765eF004cf;

    /**
     * @notice Configure peers on Arbitrum (Hub)
     */
    function configureArbitrum() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("Configuring peers on Arbitrum Hub...");
        console.log("ShareOFT:", ARBITRUM_SHAREOFT);

        vm.startBroadcast(deployerPrivateKey);

        BotVaultShareOFT shareOFT = BotVaultShareOFT(ARBITRUM_SHAREOFT);

        // Set Polygon peer
        shareOFT.setPeer(POLYGON_EID, bytes32(uint256(uint160(POLYGON_SHAREOFT))));
        console.log("  Polygon peer set:", POLYGON_SHAREOFT);

        // Set Optimism peer
        shareOFT.setPeer(OPTIMISM_EID, bytes32(uint256(uint160(OPTIMISM_SHAREOFT))));
        console.log("  Optimism peer set:", OPTIMISM_SHAREOFT);

        vm.stopBroadcast();
        console.log("Arbitrum peers configured successfully\n");
    }

    /**
     * @notice Configure peers on Polygon (Spoke)
     */
    function configurePolygon() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("Configuring peers on Polygon Spoke...");
        console.log("ShareOFT:", POLYGON_SHAREOFT);

        vm.startBroadcast(deployerPrivateKey);

        BotVaultShareOFT_Spoke shareOFT = BotVaultShareOFT_Spoke(POLYGON_SHAREOFT);

        // Set Arbitrum peer (Hub)
        shareOFT.setPeer(ARBITRUM_EID, bytes32(uint256(uint160(ARBITRUM_SHAREOFT))));
        console.log("  Arbitrum peer set:", ARBITRUM_SHAREOFT);

        // Set Optimism peer
        shareOFT.setPeer(OPTIMISM_EID, bytes32(uint256(uint160(OPTIMISM_SHAREOFT))));
        console.log("  Optimism peer set:", OPTIMISM_SHAREOFT);

        vm.stopBroadcast();
        console.log("Polygon peers configured successfully\n");
    }

    /**
     * @notice Configure peers on Optimism (Spoke)
     */
    function configureOptimism() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("Configuring peers on Optimism Spoke...");
        console.log("ShareOFT:", OPTIMISM_SHAREOFT);

        vm.startBroadcast(deployerPrivateKey);

        BotVaultShareOFT_Spoke shareOFT = BotVaultShareOFT_Spoke(OPTIMISM_SHAREOFT);

        // Set Arbitrum peer (Hub)
        shareOFT.setPeer(ARBITRUM_EID, bytes32(uint256(uint160(ARBITRUM_SHAREOFT))));
        console.log("  Arbitrum peer set:", ARBITRUM_SHAREOFT);

        // Set Polygon peer
        shareOFT.setPeer(POLYGON_EID, bytes32(uint256(uint160(POLYGON_SHAREOFT))));
        console.log("  Polygon peer set:", POLYGON_SHAREOFT);

        vm.stopBroadcast();
        console.log("Optimism peers configured successfully\n");
    }
}
