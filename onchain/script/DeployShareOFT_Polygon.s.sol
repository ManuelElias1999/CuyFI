// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BotVaultShareOFT_Spoke} from "../contracts/BotVaultShareOFT_Spoke.sol";
import {PolygonSpokeConfig} from "../contracts/config/PolygonSpokeConfig.sol";

/**
 * @title DeployShareOFT_Polygon
 * @notice Deployment script for BotVaultShareOFT on Polygon
 */
contract DeployShareOFT_Polygon is Script {
    using PolygonSpokeConfig for *;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying ShareOFT (Spoke) on Polygon");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Spoke ShareOFT on Polygon
        BotVaultShareOFT_Spoke shareOFT = new BotVaultShareOFT_Spoke(
            PolygonSpokeConfig.LAYERZERO_ENDPOINT,
            deployer
        );

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY - POLYGON");
        console.log("========================================");
        console.log("ShareOFT:", address(shareOFT));
        console.log("LayerZero Endpoint:", PolygonSpokeConfig.LAYERZERO_ENDPOINT);
        console.log("Owner:", deployer);
        console.log("========================================");
        console.log("\nNext steps:");
        console.log("1. Save this ShareOFT address");
        console.log("2. Deploy ShareOFT on Optimism");
        console.log("3. Configure peers on all chains");
        console.log("========================================");
    }
}
