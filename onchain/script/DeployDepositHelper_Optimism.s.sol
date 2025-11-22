// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../contracts/CrossChainDepositHelper.sol";

contract DeployDepositHelper_Optimism is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address usdtOft = 0xF03b4d9AC1D5d1E7c4cEf54C2A313b9fe051A0aD; // Optimism USDT OFT (correct one)
        address composer = 0x416C59C8e48C4a712072f34dEfdFb6FB1d0dfC84; // Arbitrum Composer

        CrossChainDepositHelper helper = new CrossChainDepositHelper(usdtOft, composer);

        console.log("CrossChainDepositHelper deployed at:", address(helper));
        console.log("USDT OFT (Optimism):", usdtOft);
        console.log("Composer (Arbitrum):", composer);

        vm.stopBroadcast();
    }
}
