# ShareOFT Spoke Deployments

## Deployed Addresses

### Polygon (Chain ID: 137)

| Contract | Address | Status |
|----------|---------|--------|
| **ShareOFT_Spoke** | `0x0f6001507Dd8B6eAec1a63AC782DE18538bD1d15` | ✅ Verified |

- **Block Explorer**: https://polygonscan.com/address/0x0f6001507Dd8B6eAec1a63AC782DE18538bD1d15
- **LayerZero Endpoint**: `0x1a44076050125825900e736c501f859c50fE728c`
- **LayerZero EID**: `30109`
- **Owner**: `0xc5c5A0220c1AbFCfA26eEc68e55d9b689193d6b2`

**Peers Configured**:
- ✅ Arbitrum Hub: `0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE` (EID: 30110)
- ✅ Optimism Spoke: `0x20D98107660c12331d344dFE90E573765eF004cf` (EID: 30111)

---

### Optimism (Chain ID: 10)

| Contract | Address | Status |
|----------|---------|--------|
| **ShareOFT_Spoke** | `0x20D98107660c12331d344dFE90E573765eF004cf` | ✅ Verified |

- **Block Explorer**: https://optimistic.etherscan.io/address/0x20D98107660c12331d344dFE90E573765eF004cf
- **LayerZero Endpoint**: `0x1a44076050125825900e736c501f859c50fE728c`
- **LayerZero EID**: `30111`
- **Owner**: `0xc5c5A0220c1AbFCfA26eEc68e55d9b689193d6b2`

**Peers Configured**:
- ✅ Arbitrum Hub: `0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE` (EID: 30110)
- ✅ Polygon Spoke: `0x0f6001507Dd8B6eAec1a63AC782DE18538bD1d15` (EID: 30109)

---

## Hub (Arbitrum)

For reference, the Hub ShareOFT on Arbitrum:

| Contract | Address | Chain |
|----------|---------|-------|
| **ShareOFT (Hub)** | `0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE` | Arbitrum (42161) |

**Peers Configured on Hub**:
- ✅ Polygon Spoke: `0x0f6001507Dd8B6eAec1a63AC782DE18538bD1d15` (EID: 30109)
- ✅ Optimism Spoke: `0x20D98107660c12331d344dFE90E573765eF004cf` (EID: 30111)

---

## Complete Network Topology

```
                    Arbitrum Hub (30110)
                    0xB7C8...F3BfE
                          |
         +----------------+----------------+
         |                                 |
    Polygon (30109)                  Optimism (30111)
    0x0f60...1d15                    0x20D9...04cf
         |                                 |
         +---------------------------------+
```

All chains can now bridge shares to each other via LayerZero OFT.

---

## Deployment Details

### Transaction Hashes

**Polygon Deployment**:
- See: `/home/oydual3/CuyFI/onchain/broadcast/DeployShareOFT_Polygon.s.sol/137/run-latest.json`

**Optimism Deployment**:
- See: `/home/oydual3/CuyFI/onchain/broadcast/DeployShareOFT_Optimism.s.sol/10/run-latest.json`

### Configuration Transactions

**Arbitrum Peer Config**:
- See: `/home/oydual3/CuyFI/onchain/broadcast/ConfigureShareOFTPeers.s.sol/42161/configureArbitrum-latest.json`

**Polygon Peer Config**:
- See: `/home/oydual3/CuyFI/onchain/broadcast/ConfigureShareOFTPeers.s.sol/137/configurePolygon-latest.json`

**Optimism Peer Config**:
- See: `/home/oydual3/CuyFI/onchain/broadcast/ConfigureShareOFTPeers.s.sol/10/configureOptimism-latest.json`

---

## Usage

### Bridging Shares from Arbitrum to Polygon

```bash
# On Arbitrum Hub
cast send 0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE \
  "send((uint32,bytes32,uint256,uint256,bytes,bytes,bytes),uint256,uint256)" \
  "(30109,0x000000000000000000000000RECEIVER_ADDRESS,AMOUNT,0,,0x,0x)" \
  0 \
  0 \
  --value 0.001ether \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --private-key $PRIVATE_KEY
```

### Bridging Shares from Polygon to Arbitrum

```bash
# On Polygon Spoke
cast send 0x0f6001507Dd8B6eAec1a63AC782DE18538bD1d15 \
  "send((uint32,bytes32,uint256,uint256,bytes,bytes,bytes),uint256,uint256)" \
  "(30110,0x000000000000000000000000RECEIVER_ADDRESS,AMOUNT,0,,0x,0x)" \
  0 \
  0 \
  --value 0.001ether \
  --rpc-url https://polygon-rpc.com \
  --private-key $PRIVATE_KEY
```

### Verify Peer Configuration

```bash
# Check Polygon peer on Arbitrum
cast call 0xB7C8d497a551cc3d67B6eaaC1e4264979c9F3BfE \
  "peers(uint32)(bytes32)" \
  30109 \
  --rpc-url https://arb1.arbitrum.io/rpc

# Should return: 0x0000000000000000000000000f6001507dd8b6eaec1a63ac782de18538bd1d15
```

---

## Notes

- All contracts are verified on their respective block explorers ✅
- All peer configurations are complete and bidirectional ✅
- LayerZero fees must be paid in native token (ETH on Arbitrum/Optimism, POL on Polygon)
- ShareOFT uses standard OFT implementation from LayerZero V2
