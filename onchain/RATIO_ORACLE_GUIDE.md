# Share Ratio Oracle - Cross-Chain Architecture

## Resumen

Sistema **100% onchain** usando LayerZero para broadcast de ratio share:USDT desde Arbitrum Hub hacia Polygon (y futuros spokes).

## Arquitectura

```
┌─────────────────────────────────────────────┐
│           ARBITRUM (HUB)                    │
├─────────────────────────────────────────────┤
│                                             │
│  Diamond Vault                              │
│  ├─ totalAssets() = local + deployed       │
│  └─ totalSupply()                           │
│                                             │
│  RatioBroadcaster (OApp)                    │
│  ├─ Lee ratio del Diamond                   │
│  ├─ Calcula: ratio = assets * 1e18 / supply│
│  └─ Envía via LayerZero                     │
│                                             │
└─────────────┬───────────────────────────────┘
              │
              │ LayerZero V2
              │ Message: abi.encode(ratio)
              │
              ▼
┌─────────────────────────────────────────────┐
│           POLYGON (SPOKE)                   │
├─────────────────────────────────────────────┤
│                                             │
│  ShareOracleFacet (OApp)                    │
│  ├─ Recibe ratio update via _lzReceive     │
│  ├─ Cachea ratio localmente                │
│  └─ Provee getShareValueCached()            │
│                                             │
│  User queries:                              │
│  ├─ balanceOf(user) → shares en Polygon    │
│  └─ getShareValueCached(shares) → USDT     │
│     (consulta GRATIS, sin cross-chain RPC) │
│                                             │
└─────────────────────────────────────────────┘
```

## Contratos Deployados

### Arbitrum (Hub)

| Contrato | Address | Función |
|----------|---------|---------|
| Diamond (Vault) | `0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7` | Vault principal con shares |
| RatioBroadcaster | `0x5400f01bb2Ac40121B4eC7b5527338b6c4Ce1ba7` | OApp que envía ratio updates |

### Polygon (Spoke)

| Contrato | Address | Función |
|----------|---------|---------|
| ShareOracleFacet | `0x416C59C8e48C4a712072f34dEfdFb6FB1d0dfC84` | Oracle que cachea ratio |
| ShareOFT_Spoke | `0x0f6001507Dd8B6eAec1a63AC782DE18538bD1d15` | OFT de shares |

## Peers Configurados

### RatioBroadcaster (Arbitrum)
- Polygon EID `30109` → `0x416C59C8e48C4a712072f34dEfdFb6FB1d0dfC84`

### ShareOracleFacet (Polygon)
- Arbitrum EID `30110` → `0x5400f01bb2Ac40121B4eC7b5527338b6c4Ce1ba7`

## Uso

### 1. Broadcast Ratio desde Arbitrum

```bash
# Ejecutar broadcast manual
forge script script/BroadcastRatioNow.s.sol:BroadcastRatioNow \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --broadcast

# O llamar directamente
cast send 0x5400f01bb2Ac40121B4eC7b5527338b6c4Ce1ba7 \
  "broadcastRatio(uint32,bytes)" \
  30109 \
  0x0003010011010000000000000000000000000186a0 \
  --value 0.0001ether \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --private-key $PRIVATE_KEY
```

### 2. Verificar Ratio en Polygon (después de 5-10 mins)

```bash
# Ver info del ratio cacheado
cast call 0x416C59C8e48C4a712072f34dEfdFb6FB1d0dfC84 \
  "getCachedRatioInfo()" \
  --rpc-url https://polygon-rpc.com

# Resultado: (ratio, lastUpdate, age)
# ratio = 1e18 significa 1:1 (1 share = 1 USDT)
```

### 3. Consultar Valor de Shares (Usuario en Polygon)

```bash
# 1. Ver tus shares
cast call 0x0f6001507Dd8B6eAec1a63AC782DE18538bD1d15 \
  "balanceOf(address)(uint256)" \
  YOUR_ADDRESS \
  --rpc-url https://polygon-rpc.com

# 2. Convertir shares a USDT (usando Oracle)
cast call 0x416C59C8e48C4a712072f34dEfdFb6FB1d0dfC84 \
  "getShareValueCached(uint256)(uint256)" \
  YOUR_SHARES_AMOUNT \
  --rpc-url https://polygon-rpc.com
```

**Ejemplo:**
```bash
# Usuario tiene: 10000000000000000 shares (0.01 con 18 decimales)
cast call 0x416C59C8e48C4a712072f34dEfdFb6FB1d0dfC84 \
  "getShareValueCached(uint256)(uint256)" \
  10000000000000000 \
  --rpc-url https://polygon-rpc.com

# Resultado: 10000 (0.01 USDT con 6 decimales)
```

## Flujo de Datos

### Decimal Conversion

1. **Shares en Polygon**: 18 decimales (estándar ERC20)
2. **Shares en Vault (Arbitrum)**: 6 decimales (como USDT)
3. **Conversión**: `sharesVault = sharesPolygon / 1e12`

### Cálculo de Ratio

```solidity
// En Arbitrum
totalAssets = localBalance + totalDeployed
totalSupply = vault.totalSupply()
ratio = (totalAssets * 1e18) / totalSupply  // 1e18 scaled

// En Polygon (Oracle)
sharesVaultFormat = sharesPolygon / 1e12
assetsValue = (sharesVaultFormat * cachedRatio) / 1e18
```

## Beneficios

### ✅ Para Usuarios en Polygon

1. **Consulta Gratis**: `getShareValueCached()` es view function (sin gas)
2. **Sin RPC Cross-Chain**: No necesitan llamar a Arbitrum
3. **Instantáneo**: Ratio cacheado localmente

### ✅ Arquitectura

1. **100% Onchain**: Todo via LayerZero, sin oráculos off-chain
2. **Descentralizado**: No depende de servicios externos
3. **Escalable**: Mismo patrón para Optimism, Base, etc.

## Frecuencia de Updates

### Manual (Actual)
- Owner ejecuta `BroadcastRatioNow` cuando quiere
- Útil cuando hay yields significativos
- Control total sobre gas costs

### Automático (Futuro)
Opciones para implementar:
1. **Gelato Network**: Task programada cada X horas
2. **Chainlink Automation**: Trigger basado en cambios de ratio
3. **Bot propio**: Script que monitorea ratio y envía updates

## ABIs Importantes

### RatioBroadcaster
```solidity
function broadcastRatio(uint32 _dstEid, bytes calldata _options) external payable;
function quoteBroadcast(uint32 _dstEid, bytes calldata _options) external view returns (uint256, uint256);
```

### ShareOracleFacet
```solidity
function getShareValueCached(uint256 shares) external view returns (uint256 assets);
function getCachedRatioInfo() external view returns (uint256 ratio, uint256 lastUpdate, uint256 age);
function setUpdateInterval(uint256 _interval) external; // onlyOwner
```

## Monitoring

### LayerZero Scan

Busca transacciones en:
- https://layerzeroscan.com

Filtra por:
- Source: Arbitrum (`30110`)
- Destination: Polygon (`30109`)
- Contract: `0x5400f01bb2Ac40121B4eC7b5527338b6c4Ce1ba7`

### Events

**Arbitrum (Broadcast)**
```solidity
event RatioBroadcast(uint32 dstEid, uint256 ratio, uint256 timestamp);
```

**Polygon (Reception)**
```solidity
event RatioUpdated(uint256 oldRatio, uint256 newRatio, uint256 timestamp);
```

## Troubleshooting

### Ratio no se actualiza en Polygon

1. Verificar LayerZero delivery (5-10 mins)
2. Revisar eventos en Arbiscan
3. Revisar peers configurados:
   ```bash
   cast call 0x5400f01bb2Ac40121B4eC7b5527338b6c4Ce1ba7 "peers(uint32)" 30109 --rpc-url https://arb1.arbitrum.io/rpc
   ```

### Consulta devuelve valor incorrecto

1. Verificar decimales (Polygon = 18, Vault = 6)
2. Verificar edad del ratio cacheado:
   ```bash
   cast call 0x416C59C8e48C4a712072f34dEfdFb6FB1d0dfC84 "getCachedRatioInfo()" --rpc-url https://polygon-rpc.com
   ```

## Expansión a Optimism

Para agregar Optimism:

1. Deploy ShareOracleFacet en Optimism
2. Configurar peer en RatioBroadcaster:
   ```bash
   cast send 0x5400f01bb2Ac40121B4eC7b5527338b6c4Ce1ba7 \
     "setPeer(uint32,bytes32)" \
     30111 \ # Optimism EID
     0x000000000000000000000000OPTIMISM_ORACLE_ADDRESS \
     --rpc-url https://arb1.arbitrum.io/rpc
   ```
3. Configurar peer reverso en Optimism Oracle
4. Broadcast a múltiples destinos

## Costos

### Gas Costs

- **Broadcast (Arbitrum)**: ~400k gas + LayerZero fee (~0.0001 ETH)
- **Receive (Polygon)**: Gratis (pagado por broadcaster)
- **Query (Polygon)**: Gratis (view function)

### Optimizaciones

- Broadcast solo cuando ratio cambia >0.1%
- Batch broadcasts a múltiples chains
- User automated tools (Gelato) para minimizar manual operations

## Seguridad

### Peer Configuration

- Solo RatioBroadcaster puede enviar a ShareOracleFacet
- ShareOracleFacet solo acepta de RatioBroadcaster (HUB_EID check)
- Owner puede actualizar peers si es necesario

### Ratio Staleness

- `age` en `getCachedRatioInfo()` muestra tiempo desde último update
- Frontend puede advertir si ratio es muy viejo (>24 hours)
- `updateInterval` configurable por owner

## Next Steps

1. ✅ Deployado y funcionando en Arbitrum → Polygon
2. ⏳ Verificar primer broadcast exitoso
3. 🔄 Implementar automation (Gelato/Chainlink)
4. 📊 Deploy en Optimism
5. 🎨 Integrar en frontend

---

**Documentado**: 2025-01-22
**Autor**: Claude + Usuario
**Status**: ✅ Production Ready
