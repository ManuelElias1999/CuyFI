# Deployment Scripts

## Production Scripts

### 1. Initial Deployment

#### DeployHub.s.sol
Deploys the complete BotVault Hub on Arbitrum including:
- Diamond contract with all facets (Core, Strategy, Yield, Swap)
- ShareOFT for cross-chain share transfers
- BotVaultComposer for cross-chain deposits

**Usage:**
```bash
forge script script/DeployHub.s.sol:DeployHub \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast \
  --verify --etherscan-api-key $ARBISCAN_API_KEY
```

#### DeployPolygonFull.s.sol
Deploys complete Polygon infrastructure:
- BotVaultSpokeOApp (LayerZero OApp for receiving USDT and ratio updates)
- BotVaultShareOFT_Spoke (for receiving shares cross-chain)
- AaveAdapter (for yield farming on Aave V3)
- CrossChainDepositHelper (for user deposits from Polygon)

**Usage:**
```bash
forge script script/DeployPolygonFull.s.sol:DeployPolygonFull \
  --rpc-url $POLYGON_RPC_URL \
  --broadcast \
  --verify --etherscan-api-key $POLYGONSCAN_API_KEY
```

---

### 2. Upgrades & Configuration

#### DeployNewComposer.s.sol
Deploys an updated Composer with OFT adapter support and configures it in the Hub.

**Usage:**
```bash
forge script script/DeployNewComposer.s.sol:DeployNewComposer \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast \
  --verify --etherscan-api-key $ARBISCAN_API_KEY
```

---

### 3. Operations

#### DepositToAavePolygon.s.sol
Deposits USDT from Polygon Spoke into Aave V3 for yield farming.

**Flow:**
1. Approves Aave Adapter as protocol
2. Deposits USDT via Spoke's `depositToProtocol()`
3. Receives aUSDT (yield-bearing tokens)

**Usage:**
```bash
forge script script/DepositToAavePolygon.s.sol:DepositToAavePolygon \
  --rpc-url $POLYGON_RPC_URL \
  --broadcast
```

#### UpdateDeploymentYield.s.sol
Updates deployment amount in Hub to reflect yield earned on destination chain.

**Flow:**
1. Gets active deployments from Hub
2. Calculates new amount (original + yield)
3. Updates deployment via `updateDeploymentAmount()`
4. Hub's `totalAssets` increases automatically
5. User share value increases

**Usage:**
```bash
# Simulates 10% yield by default
forge script script/UpdateDeploymentYield.s.sol:UpdateDeploymentYield \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast
```

---

## Production Addresses

### Arbitrum (Hub)
- **Hub Diamond**: `0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7`
- **Composer**: `0xa08f35D188DeA0a5DbBEB99BdAddF2fcF892C60B`
- **ShareOFT**: `0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE`

### Polygon (Spoke)
- **Spoke OApp**: `0x4Bf635A68d392Aa5A9e53a7c537637C73D6a4300`
- **ShareOFT**: `0x638dCb3DC5949fDED56C1ce6F756d47AA75f2B0d`
- **Aave Adapter**: `0x568f8af8c57a662a2DEa771F91Bc49d1d09a5416`
- **Deposit Helper**: `0x62be8717C2079563Cde390946123c05E8a2D407b`

---

## Complete Workflow Example

### 1. Deploy Infrastructure
```bash
# Deploy Hub on Arbitrum
forge script script/DeployHub.s.sol:DeployHub \
  --rpc-url $ARBITRUM_RPC_URL --broadcast --verify

# Deploy Spoke on Polygon
forge script script/DeployPolygonFull.s.sol:DeployPolygonFull \
  --rpc-url $POLYGON_RPC_URL --broadcast --verify
```

### 2. User Deposits & Bot Deploys to Polygon
```bash
# User deposits USDT on Arbitrum Hub (via UI or direct call)
# Bot calls Hub.deployToChain() to send USDT to Polygon via LayerZero
```

### 3. Bot Stakes in Aave on Polygon
```bash
forge script script/DepositToAavePolygon.s.sol:DepositToAavePolygon \
  --rpc-url $POLYGON_RPC_URL --broadcast
```

### 4. Update Yield Periodically
```bash
# Bot reads aToken balance on Polygon (off-chain)
# Bot updates Hub with new amount including yield
forge script script/UpdateDeploymentYield.s.sol:UpdateDeploymentYield \
  --rpc-url $ARBITRUM_RPC_URL --broadcast
```

---

## Environment Variables

Required in `.env`:
```bash
PRIVATE_KEY=your_private_key
ARBITRUM_RPC_URL=https://arbitrum-mainnet.infura.io/v3/YOUR_KEY
POLYGON_RPC_URL=https://polygon-rpc.com
ARBISCAN_API_KEY=your_arbiscan_key
POLYGONSCAN_API_KEY=your_polygonscan_key
```

---

## Aave V3 Integration

### Overview
The system supports USDT yield farming on Aave V3 via the Polygon Spoke. The AaveAdapter wraps Aave's lending pool to provide a standardized interface.

### Key Contracts
- **AaveAdapter** (Polygon): Wraps Aave V3 Pool for USDT deposits
- **BotVaultSpokeOApp** (Polygon): Manages USDT and executes yield strategies
- **Aave V3 Pool** (Polygon): `0x794a61358D6845594F94dc1DB02A252b5b4814aD`

### Yield Flow
```
Hub (Arbitrum) → LayerZero Bridge → Spoke (Polygon) → Aave Pool → aUSDT
```

### How Accounting Works
The Hub tracks deployed amounts manually via off-chain calculations:

1. **Initial Deployment**: When bridging to Polygon, Hub records the deployed amount
2. **Yield Accrual**: aUSDT balance grows over time on Polygon
3. **Manual Update**: Bot calculates total value (idle USDT + aUSDT) and updates Hub via `updateDeploymentAmount()`
4. **Share Value**: Hub's `totalAssets()` increases automatically, raising share value for users

**Important**: LayerZero is only used for USDT bridging, not for yield tracking. The bot must periodically read aToken balances and update the Hub.

### Example Yield Update
```solidity
// Off-chain (bot):
// 1. Read aToken balance on Polygon
uint256 aTokenBalance = aToken.balanceOf(spoke);
uint256 underlyingValue = aaveAdapter.getDepositTokenForReceipts(aTokenBalance);

// 2. Update Hub on Arbitrum
hub.updateDeploymentAmount(deploymentId, underlyingValue);
```

---

## Notes

- All scripts use Solidity 0.8.28
- LayerZero V2 is used for cross-chain messaging
- Aave V3 is used for yield farming on Polygon
- Scripts include verification on Arbiscan/Polygonscan
