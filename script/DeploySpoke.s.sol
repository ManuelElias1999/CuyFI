// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BotVaultDiamond} from "../onchain/contracts/BotVaultDiamond.sol";
import {BotVaultCoreFacet} from "../onchain/contracts/facets/BotVaultCoreFacet.sol";
import {BotYieldFacet} from "../onchain/contracts/facets/BotYieldFacet.sol";
import {BotSwapFacet} from "../onchain/contracts/facets/BotSwapFacet.sol";
import {PolygonSpokeConfig} from "../onchain/contracts/config/PolygonSpokeConfig.sol";
import {IDiamondCut} from "../onchain/contracts/interfaces/IDiamondCut.sol";

/**
 * @title DeploySpoke
 * @notice Deployment script for BotVault Spoke on Polygon
 * @dev Spoke doesn't need Strategy facet (no cross-chain deployment from spoke)
 */
contract DeploySpoke is Script {
    using PolygonSpokeConfig for *;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying BotVault Spoke on Polygon");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Diamond (Vault)
        console.log("\n1. Deploying Diamond...");
        BotVaultDiamond diamond = new BotVaultDiamond(deployer);
        console.log("Diamond deployed at:", address(diamond));

        // 2. Deploy Facets (no Strategy facet for spoke)
        console.log("\n2. Deploying Facets...");
        BotVaultCoreFacet coreFacet = new BotVaultCoreFacet();
        console.log("CoreFacet:", address(coreFacet));

        BotYieldFacet yieldFacet = new BotYieldFacet();
        console.log("YieldFacet:", address(yieldFacet));

        BotSwapFacet swapFacet = new BotSwapFacet();
        console.log("SwapFacet:", address(swapFacet));

        // 3. Prepare Diamond Cut
        console.log("\n3. Adding facets to Diamond...");
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);

        // Core Facet
        bytes4[] memory coreSelectors = new bytes4[](9);
        coreSelectors[0] = BotVaultCoreFacet.initialize.selector;
        coreSelectors[1] = BotVaultCoreFacet.deposit.selector;
        coreSelectors[2] = BotVaultCoreFacet.withdraw.selector;
        coreSelectors[3] = BotVaultCoreFacet.mint.selector;
        coreSelectors[4] = BotVaultCoreFacet.redeem.selector;
        coreSelectors[5] = BotVaultCoreFacet.pause.selector;
        coreSelectors[6] = BotVaultCoreFacet.unpause.selector;
        coreSelectors[7] = BotVaultCoreFacet.setFee.selector;
        coreSelectors[8] = BotVaultCoreFacet.totalAssets.selector;

        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(coreFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: coreSelectors
        });

        // Yield Facet
        bytes4[] memory yieldSelectors = new bytes4[](6);
        yieldSelectors[0] = BotYieldFacet.stakeInProtocol.selector;
        yieldSelectors[1] = BotYieldFacet.requestUnstakeFromProtocol.selector;
        yieldSelectors[2] = BotYieldFacet.finalizeUnstakeFromProtocol.selector;
        yieldSelectors[3] = BotYieldFacet.harvestRewards.selector;
        yieldSelectors[4] = BotYieldFacet.addProtocolAdapter.selector;
        yieldSelectors[5] = BotYieldFacet.removeProtocolAdapter.selector;

        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(yieldFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: yieldSelectors
        });

        // Swap Facet
        bytes4[] memory swapSelectors = new bytes4[](1);
        swapSelectors[0] = BotSwapFacet.swapAssets.selector;

        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(swapFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: swapSelectors
        });

        // Execute diamond cut
        diamond.diamondCut(cuts, address(0), "");
        console.log("Facets added successfully");

        // 4. Initialize Vault
        console.log("\n4. Initializing Vault...");
        bytes memory initData = abi.encode(
            "BotVault USDT Polygon",                  // name
            "bvUSDT-POLY",                             // symbol
            PolygonSpokeConfig.USDT_POLYGON,          // asset
            deployer,                                  // feeRecipient
            uint96(500),                               // fee (5%)
            deployer,                                  // owner
            deployer,                                  // agent (for now, same as owner)
            address(0)                                 // composer (spoke doesn't use composer)
        );

        BotVaultCoreFacet(address(diamond)).initialize(initData);
        console.log("Vault initialized");

        vm.stopBroadcast();

        // 5. Print deployment summary
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("Network: Polygon");
        console.log("Diamond (Vault):", address(diamond));
        console.log("CoreFacet:", address(coreFacet));
        console.log("YieldFacet:", address(yieldFacet));
        console.log("SwapFacet:", address(swapFacet));
        console.log("========================================");
        console.log("\nNext steps:");
        console.log("1. Deploy protocol adapters (Aave, etc.)");
        console.log("2. Configure Hub address for cross-chain communication");
        console.log("3. Approve USDT for vault operations");
    }
}
