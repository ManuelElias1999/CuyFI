// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {RatioBroadcaster} from "../contracts/RatioBroadcaster.sol";

/**
 * @title DeployRatioBroadcaster
 * @notice Deploy standalone ratio broadcaster on Arbitrum
 */
contract DeployRatioBroadcaster is Script {
    address constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant DIAMOND = 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7;

    // Polygon
    uint32 constant POLYGON_EID = 30109;
    address constant POLYGON_ORACLE = 0x416C59C8e48C4a712072f34dEfdFb6FB1d0dfC84;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying RatioBroadcaster on Arbitrum");
        console.log("Deployer:", deployer);
        console.log("Vault:", DIAMOND);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy broadcaster
        RatioBroadcaster broadcaster = new RatioBroadcaster(
            LZ_ENDPOINT,
            DIAMOND,
            deployer
        );

        console.log("RatioBroadcaster deployed:", address(broadcaster));

        // Configure peer to Polygon ShareOracleFacet
        bytes32 peerBytes32 = bytes32(uint256(uint160(POLYGON_ORACLE)));
        broadcaster.setPeer(POLYGON_EID, peerBytes32);

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("DEPLOYMENT COMPLETE");
        console.log("========================================");
        console.log("RatioBroadcaster:", address(broadcaster));
        console.log("Peer configured:");
        console.log("  Polygon EID:", POLYGON_EID);
        console.log("  Polygon Oracle:", POLYGON_ORACLE);
        console.log("========================================");
        console.log("\nTo broadcast ratio:");
        console.log("  forge script script/BroadcastRatioNow.s.sol --broadcast");
        console.log("========================================");
    }
}
