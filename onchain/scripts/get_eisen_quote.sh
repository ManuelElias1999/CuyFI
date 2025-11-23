#!/bin/bash
# Script to fetch Eisen Finance quote and prepare for swap execution
# Usage: ./scripts/get_eisen_quote.sh <fromToken> <toToken> <amount> <vaultAddress>

set -e

# Check dependencies
command -v curl >/dev/null 2>&1 || { echo "Error: curl is required"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required"; exit 1; }

# Arguments
FROM_TOKEN=${1:-"0xd3bF53DAC106A0290B0483EcBC89d40FcC961f3e"}  # Default: WFLOW
TO_TOKEN=${2:-"0xF1815bd50389c46847f0Bda824eC8da914045D14"}    # Default: STG_USDC
AMOUNT=${3:-"1000000000000000000"}  # Default: 1 WFLOW (18 decimals)
VAULT_ADDRESS=${4:-""}

# Eisen API config
EISEN_API_URL="https://hiker.hetz-01.eisenfinance.com/public/v1/quote"
EISEN_API_KEY=${EISEN_API_KEY:-""}  # Set via env var
CHAIN_ID="747"  # Flow EVM
SLIPPAGE="0.01"  # 1% slippage
INTEGRATOR="cuyfi-vault"

if [ -z "$VAULT_ADDRESS" ]; then
    echo "Error: Vault address is required"
    echo "Usage: $0 <fromToken> <toToken> <amount> <vaultAddress>"
    exit 1
fi

echo "========================================"
echo "EISEN FINANCE QUOTE FETCHER"
echo "========================================"
echo "From Token: $FROM_TOKEN"
echo "To Token:   $TO_TOKEN"
echo "Amount:     $AMOUNT"
echo "Vault:      $VAULT_ADDRESS"
echo "Slippage:   ${SLIPPAGE} (${SLIPPAGE}%)"
echo ""

# Convert addresses to lowercase for Eisen API
FROM_TOKEN_LOWER=$(echo "$FROM_TOKEN" | tr '[:upper:]' '[:lower:]')
TO_TOKEN_LOWER=$(echo "$TO_TOKEN" | tr '[:upper:]' '[:lower:]')
VAULT_LOWER=$(echo "$VAULT_ADDRESS" | tr '[:upper:]' '[:lower:]')

# Build API request
API_URL="${EISEN_API_URL}?"
API_URL="${API_URL}fromChain=${CHAIN_ID}"
API_URL="${API_URL}&toChain=${CHAIN_ID}"
API_URL="${API_URL}&fromToken=${FROM_TOKEN_LOWER}"
API_URL="${API_URL}&toToken=${TO_TOKEN_LOWER}"
API_URL="${API_URL}&fromAmount=${AMOUNT}"
API_URL="${API_URL}&fromAddress=${VAULT_LOWER}"
API_URL="${API_URL}&toAddress=${VAULT_LOWER}"
API_URL="${API_URL}&slippage=${SLIPPAGE}"
API_URL="${API_URL}&integrator=${INTEGRATOR}"

echo "Fetching quote from Eisen API..."
echo ""

# Make API request
HEADERS=""
if [ -n "$EISEN_API_KEY" ]; then
    HEADERS="-H X-EISEN-KEY: $EISEN_API_KEY"
fi

RESPONSE=$(curl -s $HEADERS "$API_URL")

# Check for errors
if echo "$RESPONSE" | jq -e '.message' > /dev/null 2>&1; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.message')
    echo "Error from Eisen API: $ERROR_MSG"
    exit 1
fi

# Extract transaction data
TARGET_CONTRACT=$(echo "$RESPONSE" | jq -r '.result.transactionRequest.to')
CALLDATA=$(echo "$RESPONSE" | jq -r '.result.transactionRequest.data')
VALUE=$(echo "$RESPONSE" | jq -r '.result.transactionRequest.value // "0"')
TO_AMOUNT=$(echo "$RESPONSE" | jq -r '.result.toAmount')
GAS_ESTIMATE=$(echo "$RESPONSE" | jq -r '.result.gas // "300000"')

# Calculate minAmountOut with slippage
SLIPPAGE_FACTOR=$(echo "$SLIPPAGE * 100" | bc)
MIN_AMOUNT_OUT=$(echo "scale=0; $TO_AMOUNT * (100 - $SLIPPAGE_FACTOR) / 100" | bc)

echo "========================================"
echo "QUOTE RECEIVED"
echo "========================================"
echo "Target Contract:  $TARGET_CONTRACT"
echo "Calldata:         ${CALLDATA:0:66}... (${#CALLDATA} bytes)"
echo "Value:            $VALUE"
echo "Expected Output:  $TO_AMOUNT"
echo "Min Output:       $MIN_AMOUNT_OUT (with ${SLIPPAGE}% slippage)"
echo "Gas Estimate:     $GAS_ESTIMATE"
echo ""

# Save to .env.eisen file for easy sourcing
cat > .env.eisen <<EOF
# Eisen Finance Quote - Generated $(date)
export EISEN_TARGET_CONTRACT=$TARGET_CONTRACT
export EISEN_CALLDATA=$CALLDATA
export SWAP_AMOUNT_IN=$AMOUNT
export SWAP_MIN_AMOUNT_OUT=$MIN_AMOUNT_OUT
export TOKEN_IN=$FROM_TOKEN
export TOKEN_OUT=$TO_TOKEN
export VAULT_ADDRESS=$VAULT_ADDRESS
export GAS_ESTIMATE=$GAS_ESTIMATE
EOF

echo "========================================"
echo "READY FOR EXECUTION"
echo "========================================"
echo "Environment variables saved to .env.eisen"
echo ""
echo "To execute the swap, run:"
echo ""
echo "  source .env.eisen"
echo "  forge script script/TestEisenSwap.s.sol \\"
echo "    --rpc-url https://mainnet.evm.nodes.onflow.org \\"
echo "    --broadcast \\"
echo "    --private-key \$PRIVATE_KEY"
echo ""
echo "Or copy these values manually:"
echo "  EISEN_TARGET_CONTRACT=$TARGET_CONTRACT"
echo "  EISEN_CALLDATA=$CALLDATA"
echo "  SWAP_AMOUNT_IN=$AMOUNT"
echo "  SWAP_MIN_AMOUNT_OUT=$MIN_AMOUNT_OUT"
echo "========================================"
