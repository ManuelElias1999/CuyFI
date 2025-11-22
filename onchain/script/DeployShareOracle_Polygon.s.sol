// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {ShareOracleFacet} from "../contracts/facets/ShareOracleFacet.sol";

/**
 * @title DeployShareOracle_Polygon
 * @notice Deploy ShareOracleFacet on Polygon
 */
contract DeployShareOracle_Polygon is Script {
    // LayerZero Endpoint on Polygon
    address constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    // Arbitrum Hub EID
    uint32 constant ARBITRUM_EID = 30110;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying ShareOracleFacet on Polygon");
        console.log("Deployer:", deployer);
        console.log("LayerZero Endpoint:", LZ_ENDPOINT);
        console.log("Hub EID (Arbitrum):", ARBITRUM_EID);

        vm.startBroadcast(deployerPrivateKey);

        ShareOracleFacet oracle = new ShareOracleFacet(
            LZ_ENDPOINT,
            ARBITRUM_EID,
            deployer
        );

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY - POLYGON");
        console.log("========================================");
        console.log("ShareOracleFacet:", address(oracle));
        console.log("Initial Ratio:", oracle.cachedRatio());
        console.log("Update Interval:", oracle.updateInterval(), "seconds");
        console.log("========================================");
        console.log("\nNext steps:");
        console.log("1. Configure peer on Arbitrum to send updates");
        console.log("2. Test getShareValueCached() with user shares");
        console.log("3. Set up automated ratio updates from hub");
        console.log("========================================");
    }
}
