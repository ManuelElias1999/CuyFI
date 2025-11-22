// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

interface IRatioBroadcaster {
    function broadcastRatio(uint32 _dstEid, bytes calldata _options) external payable;
    function quoteBroadcast(uint32 _dstEid, bytes calldata _options) external view returns (uint256, uint256);
}

interface IVault {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

/**
 * @title BroadcastRatioNow
 * @notice Execute ratio broadcast from Arbitrum to Polygon
 */
contract BroadcastRatioNow is Script {
    using OptionsBuilder for bytes;

    address constant BROADCASTER = 0x5400f01bb2Ac40121B4eC7b5527338b6c4Ce1ba7;
    address constant DIAMOND = 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7;
    uint32 constant POLYGON_EID = 30109;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Read current ratio
        uint256 totalAssets = IVault(DIAMOND).totalAssets();
        uint256 totalSupply = IVault(DIAMOND).totalSupply();
        uint256 ratio = (totalAssets * 1e18) / totalSupply;

        console.log("========================================");
        console.log("BROADCASTING RATIO TO POLYGON");
        console.log("========================================");
        console.log("Total Assets:", totalAssets);
        console.log("Total Supply:", totalSupply);
        console.log("Ratio (1e18):", ratio);
        console.log("");

        // Build options
        bytes memory options = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(100000, 0);

        console.log("Broadcasting...");

        vm.startBroadcast(deployerPrivateKey);

        // Broadcast!
        IRatioBroadcaster(BROADCASTER).broadcastRatio{value: 0.0001 ether}(
            POLYGON_EID,
            options
        );

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("BROADCAST SENT!");
        console.log("========================================");
        console.log("Wait ~5-10 minutes for LayerZero delivery");
        console.log("\nThen check on Polygon:");
        console.log("  cast call 0x416C59C8e48C4a712072f34dEfdFb6FB1d0dfC84 \\");
        console.log("    \"getCachedRatioInfo()\" \\");
        console.log("    --rpc-url https://polygon-rpc.com");
        console.log("========================================");
    }
}
