# CuyFI

**Your automated stablecoin yield agent — send, earn, and optimize instantly cross-chain.**

CuyFI is an AI-powered yield agent that automates the entire process of earning stablecoin yield across multiple chains. Users interact through a simple Telegram bot, while an LLM interprets their requests and analyzes opportunities using CaesarAI. With this data, CuyFI finds the best yield available, even if it exists on a different chain. The system uses Privy to create and manage non-custodial wallets, LayerZero for cross-chain messaging between Polygon and Arbitrum, and smart contracts to execute swaps, bridging, staking, and liquidity provisioning. CuyFI continuously monitors performance and automatically moves funds when better yield appears. The goal is to let users send stablecoins once and have an intelligent agent optimize everything else safely and seamlessly.

![Architecture Diagram](https://ethglobal.b0bd725bc77a3ea7cd3826627d01fcb6.r2.cloudflarestorage.com/projects/10i3v/images/1763896351302_Captura%20de%20pantalla%202025-11-23%20a%20la%28s%29%208.12.23%E2%80%AFa.%C2%A0m..png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=dd28f7ba85ca3162a53d5c60b5f3dd05%2F20251123%2Fauto%2Fs3%2Faws4_request&X-Amz-Date=20251123T115223Z&X-Amz-Expires=3600&X-Amz-Signature=9d3b0e0e2f3a512b952fdc40e5f6d94b8f63fc6cb59f00f3b9d13138b2da010a&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject)

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Applied Tracks](#-applied-tracks)
- [Project Structure](#-project-structure)
- [Quick Start](#-quick-start)
- [Documentation](#-documentation)
- [Contributing](#-contributing)

## ✨ Features

- **🤖 AI-Powered Agent**: LLM-based agent that interprets user intents and executes DeFi strategies
- **💬 Telegram Interface**: Simple, intuitive Telegram bot for user interactions
- **🌐 Cross-Chain Operations**: Seamless bridging and yield optimization across multiple chains
- **🔒 Non-Custodial Wallets**: Privy-powered embedded wallets for secure, user-controlled assets
- **📊 Yield Analysis**: Real-time yield opportunity analysis using CaesarAI DeepResearch
- **🔄 Auto-Rebalancing**: Automatic fund movement when better yield opportunities are detected
- **⚡ Gas Sponsorship**: Privy-powered gasless transactions for better UX
- **💎 ERC4626 Vaults**: Standard-compliant vault contracts for yield generation

## 🏗️ Architecture

CuyFI is built as an AI-orchestrated, chain-agnostic yield agent. The system consists of three main components:

### 1. **AI Agent** (`/agent`)
- LangChain-based agent with OpenAI integration
- Telegram bot interface for user interactions
- Tool-based architecture for extensible capabilities
- Wallet management via Privy SDK
- DeFi operation execution (deposits, swaps, staking)

### 2. **Smart Contracts** (`/onchain`)
- Hub & Spoke architecture with Arbitrum as the hub
- Diamond proxy pattern (EIP-2535) for upgradeable contracts
- ERC4626-compliant vaults for yield generation
- LayerZero integration for cross-chain messaging
- Protocol adapters for Aave, Pendle, and other DeFi protocols

### 3. **Avail Integration** (`/avail`)
- Nexus SDK for cross-chain bridging and execution
- Atomic bridge-and-execute operations
- Support for multiple EVM chains

### System Flow

1. **User Interaction**: User sends a message via Telegram bot
2. **Intent Interpretation**: LLM agent interprets the user's intent
3. **Yield Analysis**: Agent queries CaesarAI (via x402) for multi-chain yield opportunities
4. **Strategy Execution**: Agent executes optimal strategy via Privy wallets
5. **Cross-Chain Operations**: LayerZero and Avail Nexus handle bridging when needed
6. **Continuous Monitoring**: System monitors performance and rebalances automatically

## 🎯 Applied Tracks

### LayerZero

**Cross-Chain Messaging & Bridging**

We use LayerZero to connect our Arbitrum and Polygon vaults and enable automatic cross-chain operations. OFT Adapters bridge USDT from Polygon to Arbitrum, which acts as the main hub where yield strategies are executed. LayerZero messaging keeps share prices and vault states synchronized across chains. When the Agent detects better yield elsewhere, it performs a cross-chain bridge using LayerZero and updates balances through secure messages. The Composer on Arbitrum receives bridged funds, mints the shares, and sends them back to the user on the appropriate chain through LayerZero.

**Implementation:**
- 📁 [Smart Contracts](./onchain/contracts/)
- 📖 [Onchain Documentation](./onchain/README.md)
- 🔗 [Hub Usage Guide](./onchain/HUB_USAGE_GUIDE.md)
- 🔗 [Ratio Oracle Guide](./onchain/RATIO_ORACLE_GUIDE.md)

### Privy

**Non-Custodial Wallet Infrastructure & Gas Sponsorship**

For the AI Agent to invest in protocols, we need to create wallets in an easy and seamless way. With Privy, we generate embedded wallets and smart wallets that are later used to execute transactions on EVM chains. We use Privy to enable Gas Sponsorship for transactions, leveraging both the Privy SDK and the Privy API to query the wallets associated with each user. We also use Privy's x402 to perform micropayments on Caesar XYZ DeepResearch, allowing the agent to run research on variables before making decisions.

**Implementation:**
- 📁 [Privy Client](./agent/src/utils/privy_client.py)
- 📁 [Wallet Manager](./agent/src/utils/wallet_manager.py)
- 📖 [Agent Documentation](./agent/README.md)

### Avail

**Cross-Chain Bridge & Execution**

We are using the Nexus SDK to implement the bridge and execution. For our Agent, which seeks to invest in DeFi protocols regardless of where the user's funds are located, we need to bridge the assets and execute the order in the selected protocol. The Nexus SDK enables atomic bridge-and-execute operations, ensuring that funds are bridged and immediately deployed to the optimal yield strategy.

**Implementation:**
- 📁 [Avail Integration](./avail/main.ts)
- 📖 [Avail Documentation](./avail/README.md)

## 📁 Project Structure

```
CuyFI/
├── agent/              # AI Agent & Telegram Bot
│   ├── src/
│   │   ├── agent.py    # Main LangChain agent
│   │   ├── tools.py    # Agent tools (DeFi, wallet, etc.)
│   │   └── utils/
│   │       ├── privy_client.py      # Privy integration
│   │       └── wallet_manager.py    # Wallet management
│   ├── main.py         # CLI entry point
│   └── telegram_bot.py # Telegram bot
│
├── onchain/            # Smart Contracts
│   ├── contracts/
│   │   ├── facets/     # Diamond facets
│   │   ├── adapters/   # Protocol adapters
│   │   └── config/     # Chain configurations
│   ├── script/         # Deployment scripts
│   └── test/           # Contract tests
│
├── avail/              # Avail Nexus Integration
│   ├── main.ts         # Bridge & execute logic
│   └── polyfill.ts     # Node.js polyfills
│
└── README.md           # This file
```

## 🚀 Quick Start

### Prerequisites

- Python 3.10+ (for agent)
- Node.js 18+ (for Avail integration)
- Foundry (for smart contracts)
- OpenAI API key
- Privy credentials
- Telegram bot token (optional)

### 1. AI Agent Setup

```bash
cd agent
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Create .env file with your credentials
cp .env.example .env
# Edit .env with your API keys

# Run CLI agent
python main.py

# Or run Telegram bot
python telegram_bot.py
```

📖 [Full Agent Documentation](./agent/README.md)

### 2. Smart Contracts Setup

```bash
cd onchain
forge install
forge build

# Deploy to testnet
forge script script/DeployHub.s.sol:DeployHub \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast \
  --verify
```

📖 [Full Onchain Documentation](./onchain/README.md)  
📖 [Deployment Guide](./DEPLOYMENT.md)

### 3. Avail Integration Setup

```bash
cd avail
npm install

# Create .env file
echo "PRIVATE_KEY=your_private_key_here" > .env

# Run bridge & execute
npm start
```

📖 [Full Avail Documentation](./avail/README.md)

## 📚 Documentation

- **[Agent Documentation](./agent/README.md)** - AI agent setup, tools, and Telegram bot
- **[Onchain Documentation](./onchain/README.md)** - Smart contract architecture and deployment
- **[Avail Documentation](./avail/README.md)** - Cross-chain bridge and execution
- **[Deployment Guide](./DEPLOYMENT.md)** - Step-by-step deployment instructions
- **[Hub Usage Guide](./onchain/HUB_USAGE_GUIDE.md)** - Using the hub contracts
- **[Ratio Oracle Guide](./onchain/RATIO_ORACLE_GUIDE.md)** - Share price oracle system

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

[Your License Here]

---

**Built for ETHGlobal** | LayerZero • Privy • Avail
