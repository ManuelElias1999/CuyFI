// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BotVaultComposer} from "../contracts/BotVaultComposer.sol";

interface IComposerSetter {
    function setComposer(address _composer) external;
}

/**
 * @title DeployNewComposer
 * @notice Deploy new Composer with OFT adapter support and configure it
 */
contract DeployNewComposer is Script {
    address constant DIAMOND = 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7;
    address constant SHARE_OFT = 0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE;
    address constant USDT_OFT_ARBITRUM = 0x14E4A1B13bf7F943c8ff7C51fb60FA964A298D92;
    address constant USDT_OFT_POLYGON = 0x6BA10300f0DC58B7a1e4c0e41f5daBb7D7829e13;
    address constant USDT_OFT_ETHEREUM = 0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee;
    address constant USDT_OFT_OPTIMISM = 0xF03b4d9AC1D5d1E7c4cEf54C2A313b9fe051A0aD;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        console.log("Deploying new Composer...");

        vm.startBroadcast(pk);

        // 1. Deploy new Composer
        BotVaultComposer composer = new BotVaultComposer(
            DIAMOND,
            SHARE_OFT
        );
        console.log("New Composer:", address(composer));

        // 2. Approve USDT OFTs
        composer.setOFTApproval(USDT_OFT_ARBITRUM, true);
        composer.setOFTApproval(USDT_OFT_POLYGON, true);
        composer.setOFTApproval(USDT_OFT_ETHEREUM, true);
        composer.setOFTApproval(USDT_OFT_OPTIMISM, true);
        console.log("OFTs approved");

        // 3. Set new Composer in Diamond
        IComposerSetter(DIAMOND).setComposer(address(composer));
        console.log("Composer configured in Diamond");

        vm.stopBroadcast();

        console.log("\n=== SUCCESS ===");
        console.log("New Composer:", address(composer));
        console.log("Diamond updated");
    }
}
