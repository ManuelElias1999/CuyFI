#!/bin/bash
# Script to fetch 1inch API quote and prepare for swap execution
# Usage: ./scripts/get_1inch_quote.sh <fromToken> <toToken> <amount> <vaultAddress> [chainId]

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

# 1inch API config
ONEINCH_API_KEY=${ONEINCH_API_KEY:-""}  # Set via env var or get free key from 1inch
SLIPPAGE="1"  # 1% slippage

# Common token addresses on Polygon
USDT_POLYGON="0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
USDC_POLYGON="0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
WMATIC_POLYGON="0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
DAI_POLYGON="0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"

if [ -z "$FROM_TOKEN" ] || [ -z "$TO_TOKEN" ] || [ -z "$AMOUNT" ] || [ -z "$VAULT_ADDRESS" ]; then
    echo "Error: Missing required arguments"
    echo ""
    echo "Usage: $0 <fromToken> <toToken> <amount> <vaultAddress> [chainId]"
    echo ""
    echo "Example (Polygon - USDT to USDC):"
    echo "  $0 $USDT_POLYGON $USDC_POLYGON 1000000 0xYourVaultAddress 137"
    echo ""
    echo "Common Polygon tokens:"
    echo "  USDT:   $USDT_POLYGON"
    echo "  USDC:   $USDC_POLYGON"
    echo "  WMATIC: $WMATIC_POLYGON"
    echo "  DAI:    $DAI_POLYGON"
    exit 1
fi

echo "========================================"
echo "1INCH API QUOTE FETCHER"
echo "========================================"
echo "Chain ID:   $CHAIN_ID"
echo "From Token: $FROM_TOKEN"
echo "To Token:   $TO_TOKEN"
echo "Amount:     $AMOUNT"
echo "Vault:      $VAULT_ADDRESS"
echo "Slippage:   ${SLIPPAGE}%"
echo ""

# 1inch API endpoint
API_URL="https://api.1inch.dev/swap/v6.0/${CHAIN_ID}/swap"

# Build query params
PARAMS="src=${FROM_TOKEN}"
PARAMS="${PARAMS}&dst=${TO_TOKEN}"
PARAMS="${PARAMS}&amount=${AMOUNT}"
PARAMS="${PARAMS}&from=${VAULT_ADDRESS}"
PARAMS="${PARAMS}&receiver=${VAULT_ADDRESS}"
PARAMS="${PARAMS}&slippage=${SLIPPAGE}"
PARAMS="${PARAMS}&disableEstimate=true"
PARAMS="${PARAMS}&allowPartialFill=false"

FULL_URL="${API_URL}?${PARAMS}"

echo "Fetching quote from 1inch API..."
echo ""

# Make API request
HEADERS=""
if [ -n "$ONEINCH_API_KEY" ]; then
    HEADERS="-H \"Authorization: Bearer ${ONEINCH_API_KEY}\""
fi

RESPONSE=$(eval curl -s $HEADERS \"$FULL_URL\")

# Check for errors
if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.description // .error')
    echo "Error from 1inch API: $ERROR_MSG"
    echo ""
    echo "Full response:"
    echo "$RESPONSE" | jq .

    if [[ "$ERROR_MSG" == *"Unauthorized"* ]] || [[ "$ERROR_MSG" == *"401"* ]]; then
        echo ""
        echo "NOTE: You need a 1inch API key. Get one free at:"
        echo "  https://portal.1inch.dev/"
        echo ""
        echo "Then set it as an environment variable:"
        echo "  export ONEINCH_API_KEY=your_key_here"
    fi

    exit 1
fi

# Extract transaction data
TARGET_CONTRACT=$(echo "$RESPONSE" | jq -r '.tx.to')
CALLDATA=$(echo "$RESPONSE" | jq -r '.tx.data')
VALUE=$(echo "$RESPONSE" | jq -r '.tx.value // "0"')
TO_AMOUNT=$(echo "$RESPONSE" | jq -r '.dstAmount')
GAS_ESTIMATE=$(echo "$RESPONSE" | jq -r '.tx.gas // "300000"')

# For 1inch, toAmount already includes slippage protection
# But we can calculate a slightly lower min to be safe
MIN_AMOUNT_OUT=$(echo "scale=0; $TO_AMOUNT * 99 / 100" | bc)

echo "========================================"
echo "QUOTE RECEIVED"
echo "========================================"
echo "Target Contract:  $TARGET_CONTRACT"
echo "Calldata:         ${CALLDATA:0:66}... (${#CALLDATA} bytes)"
echo "Value:            $VALUE"
echo "Expected Output:  $TO_AMOUNT"
echo "Min Output:       $MIN_AMOUNT_OUT (safety buffer)"
echo "Gas Estimate:     $GAS_ESTIMATE"
echo ""

# Save to .env.swap file for easy sourcing
cat > .env.swap <<EOF
# 1inch Quote - Generated $(date)
export SWAP_TARGET_CONTRACT=$TARGET_CONTRACT
export SWAP_CALLDATA=$CALLDATA
export SWAP_AMOUNT_IN=$AMOUNT
export SWAP_MIN_AMOUNT_OUT=$MIN_AMOUNT_OUT
export TOKEN_IN=$FROM_TOKEN
export TOKEN_OUT=$TO_TOKEN
export VAULT_ADDRESS=$VAULT_ADDRESS
export GAS_ESTIMATE=$GAS_ESTIMATE
export CHAIN_ID=$CHAIN_ID
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
