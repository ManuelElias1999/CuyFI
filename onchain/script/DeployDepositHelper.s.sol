// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../contracts/CrossChainDepositHelper.sol";

contract DeployDepositHelper is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address usdtOft = 0x6BA10300f0DC58B7a1e4c0e41f5daBb7D7829e13; // Polygon USDT OFT
        address composer = 0xC526339b4EA5f8b7D86B54714e8d1A3e91222771; // Arbitrum Composer (NEW)

        CrossChainDepositHelper helper = new CrossChainDepositHelper(usdtOft, composer);

        console.log("CrossChainDepositHelper deployed at:", address(helper));
        console.log("Composer (Arbitrum):", composer);

        vm.stopBroadcast();
    }
}
