# Avail Nexus Bridge & Execute

A TypeScript project that demonstrates cross-chain bridging and DeFi execution using the Avail Nexus SDK. This project bridges USDT from Ethereum Mainnet to Arbitrum and automatically supplies it to Aave V3 Pool in a single transaction.

## 🚀 Features

- **Cross-Chain Bridging**: Bridge tokens from Ethereum Mainnet to Arbitrum using Avail Nexus
- **Atomic Execution**: Execute DeFi operations on the destination chain in the same transaction
- **Backend Wallet Support**: Uses Viem to create a wallet client that works server-side
- **Automatic Token Approval**: Handles token approvals automatically on the destination chain
- **TypeScript**: Fully typed with TypeScript for better developer experience

## 📋 Prerequisites

- Node.js 18+ and npm/yarn
- A wallet with USDT on Ethereum Mainnet
- Private key for the wallet (keep it secure!)

## 🛠️ Installation

### 1. Install Dependencies

```bash
npm install
```

### 2. Environment Configuration

Create a `.env` file in the `avail/` directory:

```bash
PRIVATE_KEY=your_private_key_here_0x...
```

**Security Warning**: Never commit your private key to version control. Use environment variables or secure secret management.

## 🎯 Usage

### Running the Bridge & Execute Script

```bash
npm start
```

Or using tsx directly:

```bash
npx tsx main.ts
```

### What It Does

1. **Initializes Wallet**: Creates a wallet client using Viem from your private key
2. **Connects to Avail Nexus SDK**: Initializes the SDK with a backend provider adapter
3. **Bridges USDT**: Bridges 10 USDT from Ethereum Mainnet to Arbitrum
4. **Executes on Destination**: Automatically supplies the bridged USDT to Aave V3 Pool on Arbitrum
5. **Returns Transaction Hashes**: Provides both bridge and execution transaction hashes

## 📁 Project Structure

```
avail/
├── main.ts              # Main bridge and execute script
├── polyfill.ts          # WebSocket and window polyfills for Node.js
├── package.json         # Dependencies and scripts
├── tsconfig.json        # TypeScript configuration
└── README.md           # This file
```

## 🔧 Configuration

### Current Configuration

The script is configured to:

- **Source Chain**: Ethereum Mainnet (Chain ID: 1)
- **Destination Chain**: Arbitrum One (Chain ID: 42161)
- **Token**: USDT
- **Amount**: 10 USDT (6 decimals)
- **Destination Contract**: Aave V3 Pool on Arbitrum (`0x794a61358D6845594F94dc1DB02A252b5b4814aD`)
- **Execution Function**: `supply` (Aave V3 supply function)

### Customizing the Script

You can modify the following in `main.ts`:

```typescript
// Change the amount to bridge
const amountToBridge = parseUnits('10', 6); // 10 USDT

// Change source chains
sourceChains: [1], // Ethereum Mainnet

// Change destination chain
toChainId: 42161, // Arbitrum One

// Change the execution contract and function
contractAddress: AAVE_POOL_ARB,
functionName: 'supply',
```

## 🔍 How It Works

### 1. Provider Adapter

The script creates an EIP-1193 compatible provider adapter that makes the Viem wallet client compatible with the Avail Nexus SDK:

```typescript
const backendProvider = {
  request: async (args: any) => {
    // Handles wallet requests
    return await client.request(args);
  },
  // ... other EIP-1193 methods
};
```

### 2. SDK Initialization

The Avail Nexus SDK is initialized with the backend provider:

```typescript
const sdk = new NexusSDK({
  network: 'mainnet'
});
await sdk.initialize(backendProvider);
```

### 3. Bridge & Execute

The `bridgeAndExecute` method performs both operations atomically:

- Bridges tokens from source chain to destination
- Executes the specified contract function on the destination chain
- Handles token approvals automatically if needed

## 📦 Dependencies

- **@avail-project/nexus-core**: Avail Nexus SDK for cross-chain operations
- **viem**: Ethereum library for wallet and RPC interactions
- **dotenv**: Environment variable management
- **ws**: WebSocket implementation for Node.js
- **tsx**: TypeScript execution for Node.js

## 🐛 Troubleshooting

### Common Issues

1. **Module Resolution Errors**
   - Ensure you're using Node.js 18+ with ES modules support
   - Check that `package.json` has `"type": "module"`

2. **WebSocket Connection Errors**
   - The polyfill should handle this automatically
   - Ensure `polyfill.ts` is imported before the SDK

3. **Private Key Errors**
   - Verify your `.env` file exists and contains `PRIVATE_KEY`
   - Ensure the private key starts with `0x`
   - Check that the wallet has sufficient USDT balance

4. **Transaction Failures**
   - Ensure wallet has sufficient ETH for gas fees on both chains
   - Verify the destination contract address is correct
   - Check that the ABI matches the contract function signature

5. **SDK Initialization Errors**
   - Make sure the provider adapter implements all required EIP-1193 methods
   - Verify the SDK is initialized after the provider is set up

## 🔐 Security Best Practices

1. **Never commit private keys** to version control
2. **Use environment variables** for sensitive data
3. **Use a dedicated wallet** with limited funds for testing
4. **Verify contract addresses** before executing transactions
5. **Test on testnets** before using mainnet
6. **Monitor transactions** on block explorers

## 🌐 Supported Networks

The Avail Nexus SDK supports multiple networks. You can configure:

- **Mainnet**: `'mainnet'`
- **Testnet**: `'testnet'`

Supported chains include:
- Ethereum Mainnet (1)
- Arbitrum One (42161)
- Polygon (137)
- And more...

## 📝 Example Output

```
🤖 Starting Nexus SDK with wallet: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
🚀 Sending Bridge & Execute intent...
✅ Transaction sent successfully!
Bridge hash: 0x...
Execution hash: 0x...
```

## 🔗 Related Projects

- [CuyFI Agent](../agent/) - AI agent for DeFi operations
- [Avail Nexus Documentation](https://docs.availproject.org/) - Official Avail documentation

## 📄 License

[Your License Here]

## 🤝 Contributing

[Contributing guidelines]

---

**Note**: This is a demonstration project. Always test thoroughly on testnets before using on mainnet with real funds.

