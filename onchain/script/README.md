# Deployment Scripts

## Production Scripts

### Hub (Arbitrum)
- **DeployHub.s.sol** - Deploys the complete BotVault Diamond with all facets, ShareOFT, and Composer
- **DeployRatioBroadcaster.s.sol** - Deploys RatioBroadcaster for sending ratio updates to spoke oracles

### Spoke Chains (Polygon, Optimism)
- **DeployShareOFT_Polygon.s.sol** - Deploys ShareOFT on Polygon (18 decimals)
- **DeployShareOFT_Optimism.s.sol** - Deploys ShareOFT on Optimism (18 decimals)
- **DeployDepositHelper.s.sol** - Deploys CrossChainDepositHelper on Polygon
- **DeployDepositHelper_Optimism.s.sol** - Deploys CrossChainDepositHelper on Optimism
- **DeploySpoke_Polygon.s.sol** - Deploys BotVaultSpoke on Polygon (for bot operations)
- **DeployShareOracle_Polygon.s.sol** - Deploys ShareOracleFacet on Polygon (ratio caching)

### Configuration
- **ConfigureShareOFTPeers.s.sol** - Configures LayerZero peers between Hub and all Spokes

### Operations
- **BroadcastRatioNow.s.sol** - Broadcasts current share ratio from Arbitrum to Polygon oracle

## Current Production Addresses

See:
- [HUB_ADDRESSES.md](../HUB_ADDRESSES.md) - Arbitrum Hub addresses
- [SPOKE_OFT_ADDRESSES.md](../SPOKE_OFT_ADDRESSES.md) - Spoke chain addresses

## Usage Examples

### Deploy Complete Hub on Arbitrum
```bash
forge script script/DeployHub.s.sol:DeployHub \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --broadcast \
  --verify --etherscan-api-key ITKXBDBRQ26S3NT2A3X778I7NGNWENH9VP
```

### Deploy ShareOFT on Polygon
```bash
forge script script/DeployShareOFT_Polygon.s.sol:DeployShareOFT_Polygon \
  --rpc-url https://polygon-rpc.com \
  --broadcast \
  --verify --etherscan-api-key YOUR_POLYGONSCAN_KEY
```

### Configure All Peers
```bash
forge script script/ConfigureShareOFTPeers.s.sol:ConfigureShareOFTPeers \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --broadcast
```

### Broadcast Ratio Update
```bash
forge script script/BroadcastRatioNow.s.sol:BroadcastRatioNow \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --broadcast
```

## Notes

- All scripts use Etherscan V2 unified API for verification
- Scripts include 15-second delays between verifications to respect rate limits
- Environment variables required: `PRIVATE_KEY`
