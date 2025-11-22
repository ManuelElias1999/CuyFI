// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BotVaultSpoke} from "../contracts/BotVaultSpoke.sol";
import {PolygonSpokeConfig} from "../contracts/config/PolygonSpokeConfig.sol";

/**
 * @title DeploySpoke_Polygon
 * @notice Deployment script for BotVaultSpoke on Polygon
 */
contract DeploySpoke_Polygon is Script {
    using PolygonSpokeConfig for *;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying BotVaultSpoke on Polygon");
        console.log("Deployer:", deployer);
        console.log("USDT:", PolygonSpokeConfig.USDT_POLYGON);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Spoke
        BotVaultSpoke spoke = new BotVaultSpoke(
            PolygonSpokeConfig.USDT_POLYGON, // asset
            deployer, // agent (bot address)
            deployer  // owner
        );

        console.log("\nSpoke deployed at:", address(spoke));

        // Optionally approve some protocols for testing
        // spoke.setProtocolApproval(PolygonSpokeConfig.AAVE_POOL_POLYGON, true);
        // console.log("Aave Pool approved");

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY - POLYGON SPOKE");
        console.log("========================================");
        console.log("BotVaultSpoke:", address(spoke));
        console.log("Asset (USDT):", PolygonSpokeConfig.USDT_POLYGON);
        console.log("Agent:", deployer);
        console.log("Owner:", deployer);
        console.log("========================================");
        console.log("\nNext steps:");
        console.log("1. Approve spoke address on hub's BotStrategyFacet");
        console.log("2. Fund hub with USDT for deployment");
        console.log("3. Call deployToChain() to send USDT to this spoke");
        console.log("========================================");
    }
}
