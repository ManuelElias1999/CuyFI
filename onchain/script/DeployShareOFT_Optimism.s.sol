// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BotVaultShareOFT_Spoke} from "../contracts/BotVaultShareOFT_Spoke.sol";
import {OptimismConfig} from "../contracts/config/OptimismConfig.sol";

/**
 * @title DeployShareOFT_Optimism
 * @notice Deployment script for BotVaultShareOFT on Optimism
 */
contract DeployShareOFT_Optimism is Script {
    using OptimismConfig for *;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying ShareOFT (Spoke) on Optimism");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Spoke ShareOFT on Optimism
        BotVaultShareOFT_Spoke shareOFT = new BotVaultShareOFT_Spoke(
            OptimismConfig.LAYERZERO_ENDPOINT,
            deployer
        );

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY - OPTIMISM");
        console.log("========================================");
        console.log("ShareOFT:", address(shareOFT));
        console.log("LayerZero Endpoint:", OptimismConfig.LAYERZERO_ENDPOINT);
        console.log("Owner:", deployer);
        console.log("========================================");
        console.log("\nNext steps:");
        console.log("1. Save this ShareOFT address");
        console.log("2. Configure peers on all chains");
        console.log("========================================");
    }
}
