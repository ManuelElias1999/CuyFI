# BotVault Deployment Guide

## Prerequisites

1. Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
```

2. Add your private key to `.env`:
```
PRIVATE_KEY=your_private_key_without_0x_prefix
```

3. Ensure you have ETH/MATIC for gas on the target network

## Deploy Hub on Arbitrum

```bash
# Dry run (simulation)
forge script script/DeployHub.s.sol:DeployHub --rpc-url $ARBITRUM_RPC_URL

# Actual deployment
forge script script/DeployHub.s.sol:DeployHub --rpc-url $ARBITRUM_RPC_URL --broadcast

# With verification
forge script script/DeployHub.s.sol:DeployHub --rpc-url $ARBITRUM_RPC_URL --broadcast --verify
```

## Deploy Spoke on Polygon

```bash
# Dry run (simulation)
forge script script/DeploySpoke.s.sol:DeploySpoke --rpc-url $POLYGON_RPC_URL

# Actual deployment
forge script script/DeploySpoke.s.sol:DeploySpoke --rpc-url $POLYGON_RPC_URL --broadcast

# With verification
forge script script/DeploySpoke.s.sol:DeploySpoke --rpc-url $POLYGON_RPC_URL --broadcast --verify
```

## Deployment Architecture

### Hub (Arbitrum)
- **BotVaultDiamond**: Main vault contract (EIP-2535)
- **BotVaultCoreFacet**: ERC4626 vault functionality
- **BotStrategyFacet**: Cross-chain deployment logic
- **BotYieldFacet**: Protocol adapter integration
- **BotSwapFacet**: Token swap functionality
- **BotVaultComposer**: Cross-chain deposits orchestrator

### Spoke (Polygon)
- **BotVaultDiamond**: Vault contract (EIP-2535)
- **BotVaultCoreFacet**: ERC4626 vault functionality
- **BotYieldFacet**: Protocol adapter integration
- **BotSwapFacet**: Token swap functionality

Note: Spokes don't have StrategyFacet (no cross-chain deployment from spoke)

## Next Steps After Deployment

### 1. Deploy ShareOFT
Deploy via LayerZero tooling (separate from Foundry)

### 2. Deploy Composer
```bash
forge script script/DeployComposer.s.sol:DeployComposer --rpc-url $ARBITRUM_RPC_URL --broadcast
```

### 3. Deploy Protocol Adapters
- PendleAdapter (Arbitrum)
- AaveAdapter (Arbitrum, Polygon)
- CompoundAdapter (if needed)

### 4. Configure Cross-Chain
- Set Hub address on Spoke
- Approve OFT adapters on Hub
- Configure LayerZero message endpoints

## Testing Deployment

### 1. Test Basic Vault Functions
```solidity
// Approve USDT
IERC20(USDT).approve(vault, amount);

// Deposit
BotVaultCoreFacet(vault).deposit(amount, receiver);

// Check balance
uint256 shares = IERC20(vault).balanceOf(receiver);
```

### 2. Test Cross-Chain (after full setup)
```solidity
// Deposit from Polygon to Arbitrum
BotVaultComposer(composer).depositCrossChain{value: fee}(
    amount,
    receiver,
    POLYGON_EID,
    "0x"  // extra options
);
```

## Important Notes

- Always test on testnets first
- Keep private keys secure
- Verify contracts on Etherscan/Arbiscan/Polygonscan
- Monitor gas prices before deployment
- Save deployment addresses for future reference

## Deployment Addresses

After deployment, save addresses here:

### Arbitrum (Hub)
- Diamond (Vault):
- CoreFacet:
- StrategyFacet:
- YieldFacet:
- SwapFacet:
- Composer:

### Polygon (Spoke)
- Diamond (Vault):
- CoreFacet:
- YieldFacet:
- SwapFacet:
