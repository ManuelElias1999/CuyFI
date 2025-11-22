# BotVault Hub - Guía de Uso (Arbitrum)

## Contratos Desplegados

### Contratos Principales

| Contrato | Address | Verificado |
|----------|---------|------------|
| **Diamond (Vault)** | `0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7` | ✅ |
| **ShareOFT (Hub)** | `0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE` | ✅ |
| **Composer** | `0xC526339b4EA5f8b7D86B54714e8d1A3e91222771` | ✅ |

### Facets

| Facet | Address | Verificado |
|-------|---------|------------|
| DiamondLoupeFacet | `0x9FC86569A7C38E0bDF704315e9A75Fe50efAc15d` | ✅ |
| DiamondCutFacet | `0x8E67E1aaE9e97989DE91542aFC533d9a88089Cac` | ✅ |
| BotVaultCoreFacet | `0x887a225e5D226C284fd476F0106cF2402DE9D5c2` | ✅ |
| BotStrategyFacet | `0xa45B19F5ba172c3F143332AA09B0c59B7fB606Cb` | ✅ |
| BotYieldFacet | `0x5ce451FBd4305E242226ab5a53802253fC0F77F8` | ✅ |
| BotSwapFacet | `0xf835a21226fa7e32F767FF30a6Db42475E229AbA` | ✅ |

### Otros Contratos

| Contrato | Address | Verificado |
|----------|---------|------------|
| VaultInit | `0x9C98BDaE36AcCC8b1C774eB24DFb87B6dce63F44` | ✅ |

### Configuración

- **Network**: Arbitrum Mainnet (Chain ID: 42161)
- **Asset**: USDT (`0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9`)
- **LayerZero Endpoint**: `0x1a44076050125825900e736c501f859c50fE728c`
- **Deployer**: `0xc5c5A0220c1AbFCfA26eEc68e55d9b689193d6b2`

---

## Operaciones Básicas

### 1. Depósito Local en Arbitrum

**Contract Address**: `0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7` (Diamond)

#### Paso 1: Aprobar USDT

```bash
cast send 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9 \
  "approve(address,uint256)" \
  0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 \
  1000000000 \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --private-key $PRIVATE_KEY
```

#### Paso 2: Depositar

```bash
# Depositar 1000 USDT (1000 * 1e6)
cast send 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 \
  "deposit(uint256,address)" \
  1000000000 \
  $YOUR_ADDRESS \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --private-key $PRIVATE_KEY
```

#### ABI para Depósito

```json
[
  {
    "type": "function",
    "name": "deposit",
    "inputs": [
      {"name": "assets", "type": "uint256"},
      {"name": "receiver", "type": "address"}
    ],
    "outputs": [{"name": "shares", "type": "uint256"}],
    "stateMutability": "nonpayable"
  }
]
```

---

### 2. Redeem (Retirar USDT)

**Contract Address**: `0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7` (Diamond)

```bash
# Retirar 100 shares
cast send 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 \
  "redeem(uint256,address,address)" \
  100000000 \
  $YOUR_ADDRESS \
  $YOUR_ADDRESS \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --private-key $PRIVATE_KEY
```

#### ABI para Redeem

```json
[
  {
    "type": "function",
    "name": "redeem",
    "inputs": [
      {"name": "shares", "type": "uint256"},
      {"name": "receiver", "type": "address"},
      {"name": "owner", "type": "address"}
    ],
    "outputs": [{"name": "assets", "type": "uint256"}],
    "stateMutability": "nonpayable"
  }
]
```

---

### 3. Ver Cuánto Vale un Share

**Contract Address**: `0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7` (Diamond)

```bash
# Ver cuánto USDT vale 1 share (1000000 = 1 share con 6 decimales)
cast call 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 \
  "convertToAssets(uint256)(uint256)" \
  1000000 \
  --rpc-url https://arb1.arbitrum.io/rpc

# Ver total de assets bajo gestión
cast call 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 \
  "totalAssets()(uint256)" \
  --rpc-url https://arb1.arbitrum.io/rpc

# Ver balance de shares de una address
cast call 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 \
  "balanceOf(address)(uint256)" \
  $YOUR_ADDRESS \
  --rpc-url https://arb1.arbitrum.io/rpc
```

#### ABI para Vistas

```json
[
  {
    "type": "function",
    "name": "convertToAssets",
    "inputs": [{"name": "shares", "type": "uint256"}],
    "outputs": [{"name": "assets", "type": "uint256"}],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "convertToShares",
    "inputs": [{"name": "assets", "type": "uint256"}],
    "outputs": [{"name": "shares", "type": "uint256"}],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "totalAssets",
    "inputs": [],
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "balanceOf",
    "inputs": [{"name": "account", "type": "address"}],
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view"
  }
]
```

---

### 4. Deployment del Agente (Cross-Chain)

**Contract Address**: `0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7` (Diamond)

#### LayerZero Chain IDs (EIDs)

| Chain | EID |
|-------|-----|
| Polygon | `30109` |
| Optimism | `30111` |
| Ethereum | `30101` |
| Arbitrum | `30110` |

#### Paso 1: Calcular Fee

```bash
# Quote fee para deployar a Polygon
cast call 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 \
  "quoteDeployToChain(uint256,uint32,address)" \
  1000000000 \
  30109 \
  0xRECEIVER_ADDRESS_ON_POLYGON \
  --rpc-url https://arb1.arbitrum.io/rpc
```

#### Paso 2: Deploy a Polygon

```bash
# Deployar 1000 USDT a Polygon
cast send 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 \
  "deployToChain(uint256,uint32,address)" \
  1000000000 \
  30109 \
  0xRECEIVER_ADDRESS_ON_POLYGON \
  --value 0.001ether \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --private-key $PRIVATE_KEY
```

#### Paso 3: Withdraw del Agente

```bash
# Primero necesitas el deploymentId del evento emitido
cast send 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 \
  "withdrawFromChain(bytes32)" \
  0xDEPLOYMENT_ID \
  --value 0.001ether \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --private-key $PRIVATE_KEY
```

#### Ver Estado del Deployment

```bash
# Ver información de un deployment
cast call 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 \
  "getDeployment(bytes32)" \
  0xDEPLOYMENT_ID \
  --rpc-url https://arb1.arbitrum.io/rpc

# Ver total deployado en Polygon
cast call 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 \
  "getTotalDeployedOnChain(uint32)(uint256)" \
  30109 \
  --rpc-url https://arb1.arbitrum.io/rpc
```

#### ABI para Strategy

```json
[
  {
    "type": "function",
    "name": "deployToChain",
    "inputs": [
      {"name": "amount", "type": "uint256"},
      {"name": "dstEid", "type": "uint32"},
      {"name": "receiver", "type": "address"}
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "withdrawFromChain",
    "inputs": [
      {"name": "deploymentId", "type": "bytes32"}
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "quoteDeployToChain",
    "inputs": [
      {"name": "amount", "type": "uint256"},
      {"name": "dstEid", "type": "uint32"},
      {"name": "receiver", "type": "address"}
    ],
    "outputs": [
      {
        "name": "messagingFee",
        "type": "tuple",
        "components": [
          {"name": "nativeFee", "type": "uint256"},
          {"name": "lzTokenFee", "type": "uint256"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getDeployment",
    "inputs": [{"name": "deploymentId", "type": "bytes32"}],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "components": [
          {"name": "amount", "type": "uint256"},
          {"name": "dstEid", "type": "uint32"},
          {"name": "receiver", "type": "address"},
          {"name": "active", "type": "bool"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getTotalDeployedOnChain",
    "inputs": [{"name": "dstEid", "type": "uint32"}],
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getActiveDeployments",
    "inputs": [],
    "outputs": [{"name": "", "type": "bytes32[]"}],
    "stateMutability": "view"
  }
]
```

---

## Ejemplo Completo: Depositar y Deployar a Polygon

```bash
#!/bin/bash

# Configuración
VAULT="0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7"
USDT="0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"
RPC="https://arb1.arbitrum.io/rpc"
POLYGON_EID=30109

# 1. Aprobar USDT
echo "Aprobando USDT..."
cast send $USDT \
  "approve(address,uint256)" \
  $VAULT \
  1000000000 \
  --rpc-url $RPC \
  --private-key $PRIVATE_KEY

# 2. Depositar 1000 USDT
echo "Depositando 1000 USDT..."
cast send $VAULT \
  "deposit(uint256,address)" \
  1000000000 \
  $YOUR_ADDRESS \
  --rpc-url $RPC \
  --private-key $PRIVATE_KEY

# 3. Ver shares recibidos
echo "Shares recibidos:"
cast call $VAULT \
  "balanceOf(address)(uint256)" \
  $YOUR_ADDRESS \
  --rpc-url $RPC

# 4. Quote fee para deploy
echo "Calculando fee para deploy..."
FEE=$(cast call $VAULT \
  "quoteDeployToChain(uint256,uint32,address)" \
  500000000 \
  $POLYGON_EID \
  0xRECEIVER_ON_POLYGON \
  --rpc-url $RPC)

echo "Fee: $FEE"

# 5. Deploy 500 USDT a Polygon
echo "Deployando a Polygon..."
cast send $VAULT \
  "deployToChain(uint256,uint32,address)" \
  500000000 \
  $POLYGON_EID \
  0xRECEIVER_ON_POLYGON \
  --value 0.001ether \
  --rpc-url $RPC \
  --private-key $PRIVATE_KEY

echo "Deployment completado!"
```

---

## Notas Importantes

1. **Decimales**: USDT en Arbitrum usa 6 decimales, así que 1 USDT = 1000000
2. **Gas Fees**: Los deployments cross-chain requieren pagar LayerZero fees en ETH (usar `--value`)
3. **Approvals**: Siempre aprobar USDT antes de depositar
4. **OFT Approvals**: Los OFTs de Polygon y Arbitrum ya están aprobados para deployments
5. **Share Value**: El valor de un share puede aumentar con yields generados en las chains remotas

---

## Block Explorers

- **Arbitrum**: https://arbiscan.io/address/0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7
- **ShareOFT**: https://arbiscan.io/address/0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE
- **Composer**: https://arbiscan.io/address/0xC526339b4EA5f8b7D86B54714e8d1A3e91222771

Todos los contratos están verificados ✅
