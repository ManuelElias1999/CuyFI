// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BotVaultDiamond} from "../onchain/contracts/BotVaultDiamond.sol";
import {BotVaultCoreFacet} from "../onchain/contracts/facets/BotVaultCoreFacet.sol";
import {BotStrategyFacet} from "../onchain/contracts/facets/BotStrategyFacet.sol";
import {BotYieldFacet} from "../onchain/contracts/facets/BotYieldFacet.sol";
import {BotSwapFacet} from "../onchain/contracts/facets/BotSwapFacet.sol";
import {BotVaultComposer} from "../onchain/contracts/BotVaultComposer.sol";
import {PendleAdapter} from "../onchain/contracts/adapters/PendleAdapter.sol";
import {ArbitrumHubConfig} from "../onchain/contracts/config/ArbitrumHubConfig.sol";
import {IDiamondCut} from "../onchain/contracts/interfaces/IDiamondCut.sol";

/**
 * @title DeployHub
 * @notice Deployment script for BotVault Hub on Arbitrum
 */
contract DeployHub is Script {
    using ArbitrumHubConfig for *;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying BotVault Hub on Arbitrum");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Diamond (Vault)
        console.log("\n1. Deploying Diamond...");
        BotVaultDiamond diamond = new BotVaultDiamond(deployer);
        console.log("Diamond deployed at:", address(diamond));

        // 2. Deploy Facets
        console.log("\n2. Deploying Facets...");
        BotVaultCoreFacet coreFacet = new BotVaultCoreFacet();
        console.log("CoreFacet:", address(coreFacet));

        BotStrategyFacet strategyFacet = new BotStrategyFacet();
        console.log("StrategyFacet:", address(strategyFacet));

        BotYieldFacet yieldFacet = new BotYieldFacet();
        console.log("YieldFacet:", address(yieldFacet));

        BotSwapFacet swapFacet = new BotSwapFacet();
        console.log("SwapFacet:", address(swapFacet));

        // 3. Prepare Diamond Cut
        console.log("\n3. Adding facets to Diamond...");
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](4);

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

        // Strategy Facet
        bytes4[] memory strategySelectors = new bytes4[](3);
        strategySelectors[0] = BotStrategyFacet.deployToChain.selector;
        strategySelectors[1] = BotStrategyFacet.receiveFromChain.selector;
        strategySelectors[2] = BotStrategyFacet.approveOFT.selector;

        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(strategyFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: strategySelectors
        });

        // Yield Facet
        bytes4[] memory yieldSelectors = new bytes4[](6);
        yieldSelectors[0] = BotYieldFacet.stakeInProtocol.selector;
        yieldSelectors[1] = BotYieldFacet.requestUnstakeFromProtocol.selector;
        yieldSelectors[2] = BotYieldFacet.finalizeUnstakeFromProtocol.selector;
        yieldSelectors[3] = BotYieldFacet.harvestRewards.selector;
        yieldSelectors[4] = BotYieldFacet.addProtocolAdapter.selector;
        yieldSelectors[5] = BotYieldFacet.removeProtocolAdapter.selector;

        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(yieldFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: yieldSelectors
        });

        // Swap Facet
        bytes4[] memory swapSelectors = new bytes4[](1);
        swapSelectors[0] = BotSwapFacet.swapAssets.selector;

        cuts[3] = IDiamondCut.FacetCut({
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
            "BotVault USDT",                          // name
            "bvUSDT",                                  // symbol
            ArbitrumHubConfig.USDT_ARBITRUM,          // asset
            deployer,                                  // feeRecipient
            uint96(500),                               // fee (5%)
            deployer,                                  // owner
            deployer,                                  // agent (for now, same as owner)
            address(0)                                 // composer (will set later)
        );

        BotVaultCoreFacet(address(diamond)).initialize(initData);
        console.log("Vault initialized");

        // 5. Deploy Composer (needs vault address first)
        console.log("\n5. Deploying Composer...");
        // Note: Share OFT needs to be deployed separately via LayerZero tooling
        // For now, we'll use a placeholder
        address shareOFT = address(0); // TODO: Deploy ShareOFT via LayerZero

        if (shareOFT == address(0)) {
            console.log("WARNING: ShareOFT not deployed yet");
            console.log("Skipping Composer deployment");
            console.log("Deploy ShareOFT first, then run DeployComposer.s.sol");
        } else {
            BotVaultComposer composer = new BotVaultComposer(
                address(diamond),
                shareOFT
            );
            console.log("Composer deployed at:", address(composer));

            // Approve USDT OFTs for cross-chain deposits
            composer.setOFTApproval(ArbitrumHubConfig.USDT_OFT_ARBITRUM, true);
            composer.setOFTApproval(ArbitrumHubConfig.USDT_OFT_POLYGON, true);
            composer.setOFTApproval(ArbitrumHubConfig.USDT_OFT_ETHEREUM, true);
            composer.setOFTApproval(ArbitrumHubConfig.USDT_OFT_OPTIMISM, true);
            console.log("OFTs approved");
        }

        vm.stopBroadcast();

        // 6. Print deployment summary
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("Network: Arbitrum");
        console.log("Diamond (Vault):", address(diamond));
        console.log("CoreFacet:", address(coreFacet));
        console.log("StrategyFacet:", address(strategyFacet));
        console.log("YieldFacet:", address(yieldFacet));
        console.log("SwapFacet:", address(swapFacet));
        console.log("========================================");
        console.log("\nNext steps:");
        console.log("1. Deploy ShareOFT via LayerZero");
        console.log("2. Run DeployComposer.s.sol with ShareOFT address");
        console.log("3. Deploy protocol adapters (Pendle, Aave, etc.)");
        console.log("4. Deploy spokes on other chains");
    }
}
