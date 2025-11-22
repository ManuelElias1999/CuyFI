# Hub Deployment - Arbitrum

**Date:** 2025-11-22
**Network:** Arbitrum Mainnet
**Deployer:** `0xc5c5A0220c1AbFCfA26eEc68e55d9b689193d6b2`

---

## Main Contracts

```
Diamond (Vault):    0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7
ShareOFT (Hub):     0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE
Composer:           0xC526339b4EA5f8b7D86B54714e8d1A3e91222771
```

## Facets

```
DiamondLoupeFacet:  0x9FC86569A7C38E0bDF704315e9A75Fe50efAc15d
DiamondCutFacet:    0x8E67E1aaE9e97989DE91542aFC533d9a88089Cac
BotVaultCoreFacet:  0x887a225e5D226C284fd476F0106cF2402DE9D5c2
BotStrategyFacet:   0xa45B19F5ba172c3F143332AA09B0c59B7fB606Cb
BotYieldFacet:      0x5ce451FBd4305E242226ab5a53802253fC0F77F8
BotSwapFacet:       0xf835a21226fa7e32F767FF30a6Db42475E229AbA
VaultInit:          0x9C98BDaE36AcCC8b1C774eB24DFb87B6dce63F44
```

## Config

- **Asset:** USDT `0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9`
- **Symbol:** bvUSDT
- **Decimals:** 6

## OFT Approvals ✅

Composer & StrategyFacet tienen aprobados:
- Arbitrum: `0x14E4A1B13bf7F943c8ff7C51fb60FA964A298D92`
- Polygon: `0x6BA10300f0DC58B7a1e4c0e41f5daBb7D7829e13`
- Ethereum: `0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee`
- Optimism: `0xF03b4d9AC1D5d1E7c4cEf54C2A313b9fe051A0aD`

---

## TODO

1. ❌ Verificar contratos en Arbiscan
2. ❌ Configurar ShareOFT peers (Polygon, Optimism)
3. ❌ Deployar/actualizar DepositHelper en Polygon y Optimism con nueva Composer address
