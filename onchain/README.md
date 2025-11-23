# CuyFI Contracts Architecture

## Hub & Spoke Architecture

### Hub (Arbitrum)
The main vault deployment with all core functionality.

#### Core Contracts
- **BotVaultDiamond.sol** - Diamond proxy contract (EIP-2535)
- **VaultInit.sol** - Initialization contract for the diamond

#### Facets
- **BotVaultCoreFacet.sol** - Core vault functionality (ERC4626)
- **BotStrategyFacet.sol** - Strategy management and cross-chain deployments
- **BotSwapFacet.sol** - Token swapping functionality
- **BotYieldFacet.sol** - Yield farming functionality
- **DiamondCutFacet.sol** - Diamond upgrade functionality
- **DiamondLoupeFacet.sol** - Diamond inspection functionality

#### Cross-Chain
- **BotVaultComposer.sol** - Handles cross-chain deposits with pending deposit pattern
- **BotVaultShareOFT.sol** - LayerZero OFT Adapter for cross-chain shares (18 decimals)
- **RatioBroadcaster.sol** - OApp for broadcasting share ratio to spoke oracles

### Spoke Chains (Polygon, Optimism, etc.)
Simplified deployments on other chains.

#### Spoke Contracts
- **BotVaultSpoke.sol** - Simplified spoke vault for bot operations
- **BotVaultShareOFT_Spoke.sol** - Spoke-side ShareOFT (18 decimals)
- **CrossChainDepositHelper.sol** - User-facing helper for cross-chain deposits

#### Spoke Facets
- **ShareOracleFacet.sol** - Caches share ratio from hub for instant, free queries

## Libraries
- **BotVaultLib.sol** - Shared vault logic and storage
- **ChainlinkOracleHelper.sol** - Price oracle helpers

## Adapters
- **PendleAdapter.sol** - Pendle protocol integration

## Configuration
- **ArbitrumHubConfig.sol** - Hub configuration
- **PolygonSpokeConfig.sol** - Polygon spoke configuration
- **OptimismConfig.sol** - Optimism spoke configuration

## Interfaces
All interface definitions are in `/interfaces/`:
- **IBotVaultCore.sol** - Core vault interface
- **IBotStrategy.sol** - Strategy interface
- **IBotSwap.sol** - Swap interface
- **IBotYield.sol** - Yield interface
- **IProtocolAdapter.sol** - Protocol adapter interface
- **IDiamondCut.sol** - Diamond cut interface
- **IDiamondLoupe.sol** - Diamond loupe interface

## Key Features

### Pending Deposits Pattern
The Composer uses a two-step deposit pattern:
1. **Automatic**: If user provides enough ETH, shares are sent back automatically
2. **Manual (Pending)**: If return trip fails (insufficient ETH), deposit is saved as "pending" and user can finalize later

This prevents fund loss while allowing flexible gas management.

### Decimal Handling
- **Vault**: 6 decimals (matches USDT)
- **ShareOFT**: 18 decimals (standard for cross-chain compatibility)
- LayerZero OFT handles conversion automatically

### Security
- ReentrancyGuard on all external functions
- OFT approval system (only approved OFTs can deposit)
- Slippage protection on all swaps and deposits
- 7-day expiration on pending deposits
