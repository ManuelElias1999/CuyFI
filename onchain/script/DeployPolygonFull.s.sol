// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BotVaultSpokeOApp} from "../contracts/BotVaultSpokeOApp.sol";
import {BotVaultShareOFT_Spoke} from "../contracts/BotVaultShareOFT_Spoke.sol";
import {AaveAdapter} from "../contracts/adapters/AaveAdapter.sol";
import {CrossChainDepositHelper} from "../contracts/CrossChainDepositHelper.sol";

contract DeployPolygonFull is Script {
    address constant USDT_POLYGON = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address constant USDT_OFT_POLYGON = 0x6BA10300f0DC58B7a1e4c0e41f5daBb7D7829e13;
    address constant AAVE_POOL_POLYGON = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address constant LAYERZERO_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant COMPOSER_ARBITRUM = 0xC526339b4EA5f8b7D86B54714e8d1A3e91222771;
    address constant HUB_DIAMOND = 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7;
    uint32 constant ARBITRUM_EID = 30110;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        console.log("Deploying to Polygon...");
        console.log("Deployer:", deployer);

        vm.startBroadcast(pk);

        // 1. Deploy Spoke OApp
        BotVaultSpokeOApp spoke = new BotVaultSpokeOApp(
            USDT_POLYGON,
            LAYERZERO_ENDPOINT,
            deployer
        );
        console.log("Spoke:", address(spoke));

        // 2. Deploy ShareOFT
        BotVaultShareOFT_Spoke shareOFT = new BotVaultShareOFT_Spoke(
            LAYERZERO_ENDPOINT,
            deployer
        );
        console.log("ShareOFT:", address(shareOFT));

        // 3. Deploy AaveAdapter
        AaveAdapter aave = new AaveAdapter(USDT_POLYGON, AAVE_POOL_POLYGON);
        console.log("AaveAdapter:", address(aave));

        // 4. Deploy DepositHelper
        CrossChainDepositHelper helper = new CrossChainDepositHelper(
            USDT_OFT_POLYGON,
            COMPOSER_ARBITRUM
        );
        console.log("DepositHelper:", address(helper));

        // 5. Configure Spoke
        spoke.setPeer(ARBITRUM_EID, bytes32(uint256(uint160(HUB_DIAMOND))));
        spoke.setProtocolApproval(AAVE_POOL_POLYGON, true);
        console.log("Spoke configured");

        // 6. Configure ShareOFT
        shareOFT.setPeer(ARBITRUM_EID, bytes32(uint256(uint160(HUB_DIAMOND))));
        console.log("ShareOFT configured");

        vm.stopBroadcast();

        console.log("\n=== SUMMARY ===");
        console.log("Spoke:", address(spoke));
        console.log("ShareOFT:", address(shareOFT));
        console.log("AaveAdapter:", address(aave));
        console.log("DepositHelper:", address(helper));
        console.log("\nUpdate .env:");
        console.log("SPOKE_VAULT_ADDRESS=", address(spoke));
        console.log("SHARE_OFT_POLYGON=", address(shareOFT));
        console.log("AAVE_ADAPTER_ADDRESS=", address(aave));
    }
}
