// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {BotVaultDiamond} from "../contracts/BotVaultDiamond.sol";
import {BotVaultCoreFacet} from "../contracts/facets/BotVaultCoreFacet.sol";
import {BotStrategyFacet} from "../contracts/facets/BotStrategyFacet.sol";
import {BotYieldFacet} from "../contracts/facets/BotYieldFacet.sol";
import {BotSwapFacet} from "../contracts/facets/BotSwapFacet.sol";
import {DiamondLoupeFacet} from "../contracts/facets/DiamondLoupeFacet.sol";
import {DiamondCutFacet} from "../contracts/facets/DiamondCutFacet.sol";
import {BotVaultComposer} from "../contracts/BotVaultComposer.sol";
import {BotVaultShareOFT} from "../contracts/BotVaultShareOFT.sol";
import {PendleAdapter} from "../contracts/adapters/PendleAdapter.sol";
import {ArbitrumHubConfig} from "../contracts/config/ArbitrumHubConfig.sol";
import {IDiamondCut} from "../contracts/interfaces/IDiamondCut.sol";
import {VaultInit} from "../contracts/VaultInit.sol";

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
        DiamondLoupeFacet loupeFacet = new DiamondLoupeFacet();
        console.log("DiamondLoupeFacet:", address(loupeFacet));

        DiamondCutFacet cutFacet = new DiamondCutFacet();
        console.log("DiamondCutFacet:", address(cutFacet));

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
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](6);

        // Diamond Loupe Facet
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;

        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(loupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Diamond Cut Facet
        bytes4[] memory cutSelectors = new bytes4[](1);
        cutSelectors[0] = DiamondCutFacet.diamondCut.selector;

        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(cutFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: cutSelectors
        });

        // Core Facet (ERC4626 + ERC20 + Custom)
        bytes4[] memory coreSelectors = new bytes4[](30);
        coreSelectors[0] = BotVaultCoreFacet.initialize.selector;
        coreSelectors[1] = BotVaultCoreFacet.deposit.selector;
        coreSelectors[2] = BotVaultCoreFacet.withdraw.selector;
        coreSelectors[3] = BotVaultCoreFacet.mint.selector;
        coreSelectors[4] = BotVaultCoreFacet.redeem.selector;
        coreSelectors[5] = BotVaultCoreFacet.pause.selector;
        coreSelectors[6] = BotVaultCoreFacet.unpause.selector;
        coreSelectors[7] = BotVaultCoreFacet.setFee.selector;
        coreSelectors[8] = BotVaultCoreFacet.totalAssets.selector;
        coreSelectors[9] = BotVaultCoreFacet.getOwner.selector;
        // ERC20 functions
        coreSelectors[10] = bytes4(keccak256("name()"));
        coreSelectors[11] = bytes4(keccak256("symbol()"));
        coreSelectors[12] = bytes4(keccak256("decimals()"));
        coreSelectors[13] = bytes4(keccak256("totalSupply()"));
        coreSelectors[14] = bytes4(keccak256("balanceOf(address)"));
        coreSelectors[15] = bytes4(keccak256("transfer(address,uint256)"));
        coreSelectors[16] = bytes4(keccak256("allowance(address,address)"));
        coreSelectors[17] = bytes4(keccak256("approve(address,uint256)"));
        coreSelectors[18] = bytes4(keccak256("transferFrom(address,address,uint256)"));
        // ERC4626 view functions
        coreSelectors[19] = bytes4(keccak256("asset()"));
        coreSelectors[20] = bytes4(keccak256("convertToShares(uint256)"));
        coreSelectors[21] = bytes4(keccak256("convertToAssets(uint256)"));
        coreSelectors[22] = bytes4(keccak256("maxDeposit(address)"));
        coreSelectors[23] = bytes4(keccak256("maxMint(address)"));
        coreSelectors[24] = bytes4(keccak256("maxWithdraw(address)"));
        coreSelectors[25] = bytes4(keccak256("maxRedeem(address)"));
        coreSelectors[26] = bytes4(keccak256("previewDeposit(uint256)"));
        coreSelectors[27] = bytes4(keccak256("previewMint(uint256)"));
        coreSelectors[28] = bytes4(keccak256("previewWithdraw(uint256)"));
        coreSelectors[29] = bytes4(keccak256("previewRedeem(uint256)"));

        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(coreFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: coreSelectors
        });

        // Strategy Facet
        bytes4[] memory strategySelectors = new bytes4[](9);
        strategySelectors[0] = BotStrategyFacet.deployToChain.selector;
        strategySelectors[1] = BotStrategyFacet.withdrawFromChain.selector;
        strategySelectors[2] = BotStrategyFacet.updateDeploymentAmount.selector;
        strategySelectors[3] = BotStrategyFacet.getDeployment.selector;
        strategySelectors[4] = BotStrategyFacet.getActiveDeployments.selector;
        strategySelectors[5] = BotStrategyFacet.getTotalDeployedOnChain.selector;
        strategySelectors[6] = BotStrategyFacet.approveOFT.selector;
        strategySelectors[7] = BotStrategyFacet.isOFTApproved.selector;
        strategySelectors[8] = BotStrategyFacet.quoteDeployToChain.selector;

        cuts[3] = IDiamondCut.FacetCut({
            facetAddress: address(strategyFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: strategySelectors
        });

        // Yield Facet
        bytes4[] memory yieldSelectors = new bytes4[](8);
        yieldSelectors[0] = BotYieldFacet.depositToProtocol.selector;
        yieldSelectors[1] = BotYieldFacet.requestWithdrawal.selector;
        yieldSelectors[2] = BotYieldFacet.finalizeWithdrawal.selector;
        yieldSelectors[3] = BotYieldFacet.harvestRewards.selector;
        yieldSelectors[4] = BotYieldFacet.getPendingRewards.selector;
        yieldSelectors[5] = BotYieldFacet.isWithdrawalClaimable.selector;
        yieldSelectors[6] = BotYieldFacet.approveProtocol.selector;
        yieldSelectors[7] = BotYieldFacet.isProtocolApproved.selector;

        cuts[4] = IDiamondCut.FacetCut({
            facetAddress: address(yieldFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: yieldSelectors
        });

        // Swap Facet
        bytes4[] memory swapSelectors = new bytes4[](4);
        swapSelectors[0] = BotSwapFacet.executeSwap.selector;
        swapSelectors[1] = BotSwapFacet.executeBatchSwap.selector;
        swapSelectors[2] = BotSwapFacet.approveDex.selector;
        swapSelectors[3] = BotSwapFacet.isDexApproved.selector;

        cuts[5] = IDiamondCut.FacetCut({
            facetAddress: address(swapFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: swapSelectors
        });

        // 4. Deploy initialization contract
        console.log("\n4. Deploying VaultInit...");
        VaultInit vaultInit = new VaultInit();
        console.log("VaultInit deployed at:", address(vaultInit));

        // 5. Prepare initialization data
        bytes memory initData = abi.encode(
            "BotVault USDT",
            "bvUSDT",
            ArbitrumHubConfig.USDT_ARBITRUM,
            deployer, // feeRecipient
            ArbitrumHubConfig.DEFAULT_FEE,
            deployer, // owner
            deployer, // agent
            address(0) // composer (deploy later)
        );

        // 6. Execute diamond cut with initialization
        console.log("\n5. Adding facets to Diamond with initialization...");
        diamond.diamondCut(cuts, address(vaultInit), abi.encodeWithSelector(VaultInit.init.selector, initData));
        console.log("Facets added and vault initialized successfully");

        // 7. Deploy ShareOFT (OFT Adapter for vault shares)
        console.log("\n6. Deploying ShareOFT...");
        BotVaultShareOFT shareOFT = new BotVaultShareOFT(
            address(diamond), // token (vault shares)
            ArbitrumHubConfig.LAYERZERO_ENDPOINT, // LayerZero endpoint
            deployer // owner
        );
        console.log("ShareOFT deployed at:", address(shareOFT));

        // 8. Deploy Composer
        console.log("\n7. Deploying Composer...");
        BotVaultComposer composer = new BotVaultComposer(
            address(diamond),
            address(shareOFT)
        );
        console.log("Composer deployed at:", address(composer));

        // Approve USDT OFTs for cross-chain deposits (Composer)
        composer.setOFTApproval(ArbitrumHubConfig.USDT_OFT_ARBITRUM, true);
        composer.setOFTApproval(ArbitrumHubConfig.USDT_OFT_POLYGON, true);
        composer.setOFTApproval(ArbitrumHubConfig.USDT_OFT_ETHEREUM, true);
        composer.setOFTApproval(ArbitrumHubConfig.USDT_OFT_OPTIMISM, true);
        console.log("USDT OFTs approved for deposits in Composer");

        // Approve USDT OFTs for cross-chain deployments (Diamond/StrategyFacet)
        BotStrategyFacet(address(diamond)).approveOFT(ArbitrumHubConfig.USDT_OFT_ARBITRUM, true);
        BotStrategyFacet(address(diamond)).approveOFT(ArbitrumHubConfig.USDT_OFT_POLYGON, true);
        BotStrategyFacet(address(diamond)).approveOFT(ArbitrumHubConfig.USDT_OFT_ETHEREUM, true);
        BotStrategyFacet(address(diamond)).approveOFT(ArbitrumHubConfig.USDT_OFT_OPTIMISM, true);
        console.log("USDT OFTs approved for deployments in Diamond");

        vm.stopBroadcast();

        // 9. Print deployment summary
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("Network: Arbitrum Mainnet");
        console.log("Diamond (Vault):", address(diamond));
        console.log("VaultInit:", address(vaultInit));
        console.log("ShareOFT:", address(shareOFT));
        console.log("Composer:", address(composer));
        console.log("CoreFacet:", address(coreFacet));
        console.log("StrategyFacet:", address(strategyFacet));
        console.log("YieldFacet:", address(yieldFacet));
        console.log("SwapFacet:", address(swapFacet));
        console.log("========================================");
        console.log("\nVault initialized with:");
        console.log("  Name: BotVault USDT");
        console.log("  Symbol: bvUSDT");
        console.log("  Asset:", ArbitrumHubConfig.USDT_ARBITRUM);
        console.log("  Owner:", deployer);
        console.log("  Agent:", deployer);
        console.log("========================================");
        console.log("\nApproved USDT OFTs:");
        console.log("  Arbitrum:", ArbitrumHubConfig.USDT_OFT_ARBITRUM);
        console.log("  Polygon:", ArbitrumHubConfig.USDT_OFT_POLYGON);
        console.log("  Ethereum:", ArbitrumHubConfig.USDT_OFT_ETHEREUM);
        console.log("  Optimism:", ArbitrumHubConfig.USDT_OFT_OPTIMISM);
        console.log("========================================");
        console.log("\nNext steps:");
        console.log("1. Configure ShareOFT peers on destination chains");
        console.log("2. Deploy protocol adapters (Pendle, Aave, etc.)");
        console.log("3. Deploy spokes on other chains (optional)");
    }
}
