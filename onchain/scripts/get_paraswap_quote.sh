#!/bin/bash
# Script to fetch Paraswap API quote (NO API KEY NEEDED!)
# Usage: ./scripts/get_paraswap_quote.sh <fromToken> <toToken> <amount> <vaultAddress> [chainId]

set -e

# Check dependencies
command -v curl >/dev/null 2>&1 || { echo "Error: curl is required"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required"; exit 1; }

# Arguments
FROM_TOKEN=${1:-""}
TO_TOKEN=${2:-""}
AMOUNT=${3:-""}
VAULT_ADDRESS=${4:-""}
CHAIN_ID=${5:-"137"}  # Default: Polygon

# Paraswap config (NO API KEY NEEDED!)
SLIPPAGE="100"  # 100 = 1% slippage (in basis points)

# Common token addresses on Polygon
USDT_POLYGON="0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
USDC_POLYGON="0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"  # USDC native
USDC_E_POLYGON="0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"  # USDC.e (bridged)
WMATIC_POLYGON="0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
DAI_POLYGON="0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"

if [ -z "$FROM_TOKEN" ] || [ -z "$TO_TOKEN" ] || [ -z "$AMOUNT" ] || [ -z "$VAULT_ADDRESS" ]; then
    echo "Error: Missing required arguments"
    echo ""
    echo "Usage: $0 <fromToken> <toToken> <amount> <vaultAddress> [chainId]"
    echo ""
    echo "Example (Polygon - USDT to USDC):"
    echo "  $0 $USDT_POLYGON $USDC_E_POLYGON 1000000 0xYourVaultAddress 137"
    echo ""
    echo "Common Polygon tokens:"
    echo "  USDT:    $USDT_POLYGON (6 decimals)"
    echo "  USDC:    $USDC_POLYGON (6 decimals - native)"
    echo "  USDC.e:  $USDC_E_POLYGON (6 decimals - bridged)"
    echo "  WMATIC:  $WMATIC_POLYGON (18 decimals)"
    echo "  DAI:     $DAI_POLYGON (18 decimals)"
    exit 1
fi

echo "========================================"
echo "PARASWAP API QUOTE FETCHER"
echo "========================================"
echo "Chain ID:   $CHAIN_ID"
echo "From Token: $FROM_TOKEN"
echo "To Token:   $TO_TOKEN"
echo "Amount:     $AMOUNT"
echo "Vault:      $VAULT_ADDRESS"
echo "Slippage:   $(echo "scale=2; $SLIPPAGE / 100" | bc)%"
echo ""

# Step 1: Get price quote
echo "Step 1: Getting price quote..."
PRICE_URL="https://api.paraswap.io/prices"
PRICE_PARAMS="srcToken=${FROM_TOKEN}"
PRICE_PARAMS="${PRICE_PARAMS}&destToken=${TO_TOKEN}"
PRICE_PARAMS="${PRICE_PARAMS}&amount=${AMOUNT}"
PRICE_PARAMS="${PRICE_PARAMS}&srcDecimals=6"
PRICE_PARAMS="${PRICE_PARAMS}&destDecimals=6"
PRICE_PARAMS="${PRICE_PARAMS}&side=SELL"
PRICE_PARAMS="${PRICE_PARAMS}&network=${CHAIN_ID}"

PRICE_RESPONSE=$(curl -s "${PRICE_URL}?${PRICE_PARAMS}")

# Check for errors in price response
if echo "$PRICE_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    ERROR_MSG=$(echo "$PRICE_RESPONSE" | jq -r '.error')
    echo "Error from Paraswap API: $ERROR_MSG"
    echo ""
    echo "Full response:"
    echo "$PRICE_RESPONSE" | jq .
    exit 1
fi

PRICE_ROUTE=$(echo "$PRICE_RESPONSE" | jq -r '.priceRoute')
if [ "$PRICE_ROUTE" == "null" ]; then
    echo "Error: No price route found"
    echo "Response:"
    echo "$PRICE_RESPONSE" | jq .
    exit 1
fi

DEST_AMOUNT=$(echo "$PRICE_RESPONSE" | jq -r '.priceRoute.destAmount')
echo "Expected output: $DEST_AMOUNT"

# Step 2: Build transaction
echo ""
echo "Step 2: Building transaction..."
TX_URL="https://api.paraswap.io/transactions/${CHAIN_ID}"

TX_PAYLOAD=$(cat <<EOF
{
  "srcToken": "$FROM_TOKEN",
  "destToken": "$TO_TOKEN",
  "srcAmount": "$AMOUNT",
  "priceRoute": $PRICE_ROUTE,
  "userAddress": "$VAULT_ADDRESS",
  "partner": "cuyfi",
  "slippage": $SLIPPAGE,
  "ignoreChecks": true
}
EOF
)

TX_RESPONSE=$(curl -s -X POST "$TX_URL" \
  -H "Content-Type: application/json" \
  -d "$TX_PAYLOAD")

# Check for errors in transaction response
if echo "$TX_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    ERROR_MSG=$(echo "$TX_RESPONSE" | jq -r '.error')
    echo "Error building transaction: $ERROR_MSG"
    echo ""
    echo "Full response:"
    echo "$TX_RESPONSE" | jq .
    exit 1
fi

# Extract transaction data
TARGET_CONTRACT=$(echo "$TX_RESPONSE" | jq -r '.to')
CALLDATA=$(echo "$TX_RESPONSE" | jq -r '.data')
VALUE=$(echo "$TX_RESPONSE" | jq -r '.value // "0"')
GAS_ESTIMATE=$(echo "$TX_RESPONSE" | jq -r '.gas // "300000"')

# Calculate min amount with slippage
MIN_AMOUNT_OUT=$(echo "scale=0; $DEST_AMOUNT * (10000 - $SLIPPAGE) / 10000" | bc)

if [ -z "$TARGET_CONTRACT" ] || [ "$TARGET_CONTRACT" == "null" ] || [ -z "$CALLDATA" ] || [ "$CALLDATA" == "null" ]; then
    echo "Error: Invalid transaction data received"
    echo "Response:"
    echo "$TX_RESPONSE" | jq .
    exit 1
fi

echo "========================================"
echo "QUOTE RECEIVED"
echo "========================================"
echo "Target Contract:  $TARGET_CONTRACT"
echo "Calldata:         ${CALLDATA:0:66}... (${#CALLDATA} bytes)"
echo "Value:            $VALUE"
echo "Expected Output:  $DEST_AMOUNT"
echo "Min Output:       $MIN_AMOUNT_OUT (with slippage)"
echo "Gas Estimate:     $GAS_ESTIMATE"
echo ""

# Paraswap uses a TokenTransferProxy for approvals
# This is the standard Paraswap proxy address on all chains
PARASWAP_TOKEN_TRANSFER_PROXY="0x216B4B4Ba9F3e719726886d34a177484278Bfcae"

# Save to .env.swap file
cat > .env.swap <<EOF
# Paraswap Quote - Generated $(date)
export SWAP_TARGET_CONTRACT=$TARGET_CONTRACT
export SWAP_CALLDATA=$CALLDATA
export SWAP_AMOUNT_IN=$AMOUNT
export SWAP_MIN_AMOUNT_OUT=$MIN_AMOUNT_OUT
export TOKEN_IN=$FROM_TOKEN
export TOKEN_OUT=$TO_TOKEN
export VAULT_ADDRESS=$VAULT_ADDRESS
export GAS_ESTIMATE=$GAS_ESTIMATE
export CHAIN_ID=$CHAIN_ID
export SWAP_APPROVAL_TARGET=$PARASWAP_TOKEN_TRANSFER_PROXY
EOF

echo "========================================"
echo "READY FOR EXECUTION"
echo "========================================"
echo "Environment variables saved to .env.swap"
echo ""

# Determine RPC URL based on chain
case $CHAIN_ID in
    137)
        RPC_URL="https://polygon-rpc.com"
        CHAIN_NAME="Polygon"
        ;;
    42161)
        RPC_URL="https://arb1.arbitrum.io/rpc"
        CHAIN_NAME="Arbitrum"
        ;;
    10)
        RPC_URL="https://mainnet.optimism.io"
        CHAIN_NAME="Optimism"
        ;;
    1)
        RPC_URL="https://eth.llamarpc.com"
        CHAIN_NAME="Ethereum"
        ;;
    *)
        RPC_URL="<YOUR_RPC_URL>"
        CHAIN_NAME="Chain $CHAIN_ID"
        ;;
esac

echo "To execute the swap on $CHAIN_NAME, run:"
echo ""
echo "  source .env.swap"
echo "  forge script script/TestApiSwap.s.sol \\"
echo "    --rpc-url $RPC_URL \\"
echo "    --broadcast \\"
echo "    --private-key \$PRIVATE_KEY -vv"
echo ""
echo "========================================"
