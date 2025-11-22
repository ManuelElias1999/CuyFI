// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BotVaultDiamond} from "../contracts/BotVaultDiamond.sol";
import {BotVaultCoreFacet} from "../contracts/facets/BotVaultCoreFacet.sol";
import {ArbitrumHubConfig} from "../contracts/config/ArbitrumHubConfig.sol";
import {IDiamondCut} from "../contracts/interfaces/IDiamondCut.sol";

/**
 * @title DeploySimple
 * @notice Simplified deployment for testing - just Diamond + CoreFacet
 */
contract DeploySimple is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("DEPLOYING BOTVAULT - SIMPLE VERSION");
        console.log("========================================");
        console.log("Network:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "ETH");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Diamond
        console.log("1. Deploying Diamond...");
        BotVaultDiamond diamond = new BotVaultDiamond(deployer);
        console.log("   Diamond:", address(diamond));

        // 2. Deploy CoreFacet
        console.log("\n2. Deploying CoreFacet...");
        BotVaultCoreFacet coreFacet = new BotVaultCoreFacet();
        console.log("   CoreFacet:", address(coreFacet));

        // 3. Add CoreFacet to Diamond
        console.log("\n3. Adding CoreFacet to Diamond...");

        bytes4[] memory selectors = new bytes4[](11);
        selectors[0] = BotVaultCoreFacet.initialize.selector;
        selectors[1] = BotVaultCoreFacet.deposit.selector;
        selectors[2] = BotVaultCoreFacet.withdraw.selector;
        selectors[3] = BotVaultCoreFacet.mint.selector;
        selectors[4] = BotVaultCoreFacet.redeem.selector;
        selectors[5] = BotVaultCoreFacet.pause.selector;
        selectors[6] = BotVaultCoreFacet.unpause.selector;
        selectors[7] = BotVaultCoreFacet.setFee.selector;
        selectors[8] = BotVaultCoreFacet.totalAssets.selector;
        selectors[9] = BotVaultCoreFacet.asset.selector;
        selectors[10] = BotVaultCoreFacet.paused.selector;

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(coreFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        diamond.diamondCut(cuts, address(0), "");
        console.log("   CoreFacet added successfully");

        // 4. Initialize Vault
        console.log("\n4. Initializing Vault...");

        address asset;
        if (block.chainid == 42161) {
            // Arbitrum
            asset = ArbitrumHubConfig.USDT_ARBITRUM;
        } else {
            // For testnets or other chains, would need different config
            console.log("   WARNING: Using Arbitrum USDT address");
            asset = ArbitrumHubConfig.USDT_ARBITRUM;
        }

        bytes memory initData = abi.encode(
            "BotVault USDT",     // name
            "bvUSDT",            // symbol
            asset,               // asset (USDT)
            deployer,            // feeRecipient
            uint96(500),         // fee (5%)
            deployer,            // owner
            deployer,            // agent
            address(0)           // composer (not deployed yet)
        );

        BotVaultCoreFacet(address(diamond)).initialize(initData);
        console.log("   Vault initialized");

        vm.stopBroadcast();

        // Print summary
        console.log("\n========================================");
        console.log("DEPLOYMENT SUCCESSFUL");
        console.log("========================================");
        console.log("Vault Address:", address(diamond));
        console.log("Asset (USDT):", asset);
        console.log("Owner:", deployer);
        console.log("Fee:", "5%");
        console.log("========================================");
        console.log("\nSave this vault address for next steps!");
        console.log("\nTo verify on Arbiscan:");
        console.log("forge verify-contract", address(diamond), "BotVaultDiamond --chain arbitrum");
    }
}
