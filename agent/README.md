# LangChain AI Agent with Telegram Integration

A powerful LangChain-based AI agent with OpenAI integration, Web3 capabilities, and Telegram bot support. This agent can interact with users via command-line interface or Telegram, perform web searches, execute DeFi operations, and manage cryptocurrency wallets.

## 🚀 Features

### Core Capabilities
- **OpenAI Integration**: Uses OpenAI's GPT models (GPT-4 Turbo) via LangChain
- **Conversation Memory**: Maintains context across interactions
- **Multi-Interface Support**: Available via CLI and Telegram bot
- **Tool-Based Architecture**: Extensible tool system for adding new capabilities

### Available Tools

1. **Wallet Management** 💼
   - **Create Embedded Wallet**: Create Privy embedded wallets for users
     - Requires Privy user ID (DID format)
     - Creates Ethereum-compatible embedded wallets
   - **Get Address & Balance**: Check ETH balance of any Ethereum address
     - Works with backend wallet or any provided address
     - Returns balance in ETH and Wei
   - **Get USDT Balance**: Check USDT (Tether) balance
     - Supports multiple networks (mainnet, polygon, arbitrum, optimism, base)
     - Returns token balance with symbol and address information

2. **DeFi & Yield Generation** 🌐
   - **Deposit to Vault**: Deposit assets to generate yield on Arbitrum
     - Executes deposit function on ERC4626 vault contract
     - Automatically handles token approvals
     - Default vault: `0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7` (Arbitrum)
     - Default underlying token: USDT on Arbitrum
     - Returns transaction hash and explorer link

### Telegram Bot Features
- Interactive chat interface
- Command handlers (`/start`, `/help`, `/clear`, `/status`)
- Channel broadcasting support (optional)
- Real-time message processing
- Typing indicators for better UX
- Per-user conversation memory

## 📋 Prerequisites

- Python 3.10 or higher
- OpenAI API key
- (Optional) Telegram Bot Token for Telegram integration
- (Optional) Privy credentials for wallet operations
- (Optional) Web3 RPC URL for blockchain interactions

## 🛠️ Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd CuyFI/agent
```

### 2. Create Virtual Environment (Recommended)

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Environment Configuration

Create a `.env` file in the `agent/` directory:

```bash
# Required: OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4-turbo-preview
OPENAI_TEMPERATURE=0.7

# Optional: Agent Configuration
AGENT_VERBOSE=False
AGENT_MAX_ITERATIONS=15

# Optional: Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
TELEGRAM_CHANNEL_ID=your_channel_id_here  # Optional, for broadcasting

# Required: Backend Wallet Configuration (for executing transactions)
BACKEND_PRIVATE_KEY=your_backend_wallet_private_key_here
INFURA_PROJECT_ID=your_infura_project_id_here
NETWORK=arbitrum  # Options: mainnet, sepolia, polygon, polygon-amoy, arbitrum, optimism, base

# Optional: Privy Configuration (for wallet operations)
PRIVY_APP_ID=your_privy_app_id
PRIVY_APP_SECRET=your_privy_app_secret

# Optional: Web3 Configuration
WEB3_RPC_URL=https://polygon-rpc.com  # Or your preferred RPC endpoint
CHAIN_ID=137  # Polygon mainnet (1 for Ethereum mainnet)
```

## 🎯 Usage

### Running the CLI Agent

Start an interactive command-line session:

```bash
python main.py
```

This will start an interactive chat where you can:
- Ask questions
- Request information
- Perform calculations
- Execute Web3 operations
- Type `exit`, `quit`, or `q` to end the session

**Example Session:**
```
You: Check my wallet balance
Agent: [Returns ETH balance of backend wallet]

You: What's my USDT balance?
Agent: [Returns USDT balance on the configured network]

You: Deposit 100 USDT to generate yield
Agent: Your token was sent to vault, now we are working to generate Yield.

You: Create an embedded wallet for user did:privy:abc123
Agent: [Creates wallet and returns wallet information]
```

### Running the Telegram Bot

Start the Telegram bot:

```bash
python telegram_bot.py
```

The bot will:
- Connect to Telegram servers via polling
- Start listening for messages
- Process commands and queries
- Maintain conversation context per user

**Telegram Commands:**
- `/start` - Start the bot and see welcome message
- `/help` - Show available commands
- `/clear` - Clear conversation history
- `/status` - Check bot status and configuration

**Testing from Localhost:**
The bot works perfectly from localhost using polling. No special setup required - just run the script and start chatting!

### Using the Agent Programmatically

```python
from src.agent import LangChainAgent

# Initialize the agent
agent = LangChainAgent(
    verbose=True,
    max_iterations=15
)

# Run a query
response = agent.run("What is the capital of France?")
print(response)

# Chat with the agent (alias for run)
response = agent.chat("Calculate 123 * 456")
print(response)

# Clear conversation memory
agent.clear_memory()

# Get chat history
history = agent.get_chat_history()
```

## 🔧 Configuration Details

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `OPENAI_API_KEY` | Your OpenAI API key | `sk-...` |
| `BACKEND_PRIVATE_KEY` | Private key of backend wallet for executing transactions | `0x...` |
| `INFURA_PROJECT_ID` | Infura project ID for RPC connections | `abc123...` |

### Optional Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_MODEL` | OpenAI model to use | `gpt-4-turbo-preview` |
| `OPENAI_TEMPERATURE` | Model temperature (0-1) | `0.7` |
| `AGENT_VERBOSE` | Enable verbose output | `False` |
| `AGENT_MAX_ITERATIONS` | Max agent iterations | `15` |
| `NETWORK` | Blockchain network to use | `sepolia` |
| | Options: `mainnet`, `sepolia`, `polygon`, `polygon-amoy`, `arbitrum`, `optimism`, `base` | |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token | - |
| `TELEGRAM_CHANNEL_ID` | Telegram channel ID | - |
| `PRIVY_APP_ID` | Privy application ID | - |
| `PRIVY_APP_SECRET` | Privy application secret | - |
| `WEB3_RPC_URL` | Web3 RPC endpoint | - |
| `CHAIN_ID` | Blockchain chain ID | `1` |

## 🔐 Backend Wallet Setup

### Getting an Infura Project ID

The agent requires an Infura project ID to connect to blockchain networks:

1. Visit [Infura](https://infura.io/) and create an account
2. Create a new project in the dashboard
3. Select the networks you want to use (e.g., Arbitrum, Ethereum, Polygon)
4. Copy your Project ID
5. Add it to your `.env` file as `INFURA_PROJECT_ID`

### Setting Up Backend Wallet

The backend wallet is used to execute transactions on behalf of users:

1. **Create or Import a Wallet**
   - Generate a new wallet or import an existing one
   - **Important**: This wallet will execute transactions, so ensure it has sufficient funds for gas fees

2. **Get the Private Key**
   - Export the private key from your wallet (keep it secure!)
   - Add it to your `.env` file as `BACKEND_PRIVATE_KEY`

3. **Configure Network**
   - Set `NETWORK` in your `.env` file to your target network
   - Options: `mainnet`, `sepolia`, `polygon`, `polygon-amoy`, `arbitrum`, `optimism`, `base`
   - Default: `sepolia` (testnet)

**Security Warning**: 
- Never commit your private key to version control
- Use environment variables or secure secret management
- Consider using a dedicated wallet with limited funds for the backend
- Regularly monitor the wallet for unauthorized transactions

## 📱 Telegram Bot Setup

### Getting a Telegram Bot Token

1. Open Telegram and search for [@BotFather](https://t.me/botfather)
2. Send `/newbot` command
3. Follow the instructions to create your bot
4. Copy the bot token provided
5. Add it to your `.env` file as `TELEGRAM_BOT_TOKEN`

### Getting a Telegram Channel ID (Optional)

If you want to broadcast messages to a channel:

1. **Method 1: Using getUpdates API**
   - Add your bot as admin to the channel
   - Send a message to the channel
   - Visit: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
   - Find the `chat` object with `"type": "channel"`
   - Copy the `id` (usually negative, like `-1001234567890`)

2. **Method 2: Using @userinfobot**
   - Add `@userinfobot` to your channel
   - The bot will send channel information including the ID

3. **Method 3: Using @getidsbot**
   - Forward a message from your channel to `@getidsbot`
   - The bot will reply with the channel ID

Add the channel ID to your `.env` file as `TELEGRAM_CHANNEL_ID`.

## 🌐 Web3 & DeFi Features

### Supported Operations

#### Get Balance
Check the ETH balance of any Ethereum address:
```
You: Check balance of 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
```
Or check the backend wallet balance:
```
You: What's my wallet balance?
```

#### Get USDT Balance
Check USDT balance on supported networks:
```
You: Check USDT balance of 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
```

**Supported Networks:**
- Ethereum Mainnet
- Polygon
- Arbitrum
- Optimism
- Base
- Sepolia (testnet)
- Polygon Amoy (testnet)

#### Deposit to Vault (Generate Yield)
Deposit assets to the vault contract on Arbitrum to generate yield:
```
You: Deposit 100 USDT to generate yield
```

The agent will:
- Use the backend wallet to execute the transaction
- Automatically approve token spending if needed
- Execute the deposit transaction on the vault
- Return confirmation message

**Vault Configuration:**
- **Vault Address**: `0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7` (Arbitrum)
- **Underlying Token**: USDT on Arbitrum (`0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9`)
- **Network**: Arbitrum One

#### Create Embedded Wallet
Create a Privy embedded wallet for a user:
```
You: Create an embedded wallet for user did:privy:abc123
```

### Backend Wallet

The agent uses a backend wallet (configured via `BACKEND_PRIVATE_KEY`) to:
- Execute blockchain transactions
- Sign and send transactions automatically
- Handle token approvals
- Interact with smart contracts

**Security Note:** Keep your `BACKEND_PRIVATE_KEY` secure and never commit it to version control. The backend wallet should have sufficient funds for gas fees.

## 📁 Project Structure

```
agent/
├── main.py                    # CLI entry point
├── telegram_bot.py            # Telegram bot entry point
├── requirements.txt           # Python dependencies
├── README.md                  # This file
└── src/
    ├── __init__.py           # Package initialization
    ├── agent.py              # Main agent implementation
    ├── config.py             # Configuration management
    ├── prompts.py            # System prompts
    ├── tools.py              # Agent tools (web search, calculator, Web3, etc.)
    └── utils/
        ├── __init__.py
        ├── privy_client.py   # Privy authentication client
        └── wallet_manager.py # Wallet management utilities
```

## 🔨 Development

### Adding Custom Tools

To add a new tool, edit `src/tools.py`:

```python
from langchain_core.tools import StructuredTool
from pydantic import BaseModel, Field

class MyToolInput(BaseModel):
    """Input schema for my tool."""
    param: str = Field(description="Description of parameter")

def my_custom_tool(param: str) -> str:
    """
    Description of what the tool does.
    
    Args:
        param: Parameter description
        
    Returns:
        Result description
    """
    # Your tool logic here
    return result

def get_tools() -> list[BaseTool]:
    tools = [
        # ... existing tools ...
        StructuredTool.from_function(
            func=my_custom_tool,
            name="my_custom_tool",
            description="Description for the agent to understand when to use this tool",
            args_schema=MyToolInput,
        ),
    ]
    return tools
```

### Customizing Prompts

Edit `src/prompts.py` to customize the system prompt and agent behavior:

```python
SYSTEM_PROMPT = """Your custom system prompt here..."""
```

### Extending the Telegram Bot

To add new commands to the Telegram bot, edit `telegram_bot.py`:

```python
async def my_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle the /mycommand command."""
    await update.message.reply_text("Response message")

# In setup_handlers method:
application.add_handler(CommandHandler("mycommand", self.my_command))
```

## 🐛 Troubleshooting

### Common Issues

1. **ImportError: cannot import name 'Update' from 'telegram'**
   - **Solution**: The file was renamed from `telegram.py` to `telegram_bot.py` to avoid naming conflicts. Use `python telegram_bot.py` instead.

2. **Configuration error: OPENAI_API_KEY is required**
   - **Solution**: Make sure your `.env` file exists and contains `OPENAI_API_KEY=your_key_here`

3. **Telegram bot not responding**
   - **Solution**: 
     - Verify `TELEGRAM_BOT_TOKEN` is correct
     - Check that the bot is running (`python telegram_bot.py`)
     - Ensure your firewall allows outbound HTTPS connections

4. **Web3 operations failing**
   - **Solution**: 
     - Verify `BACKEND_PRIVATE_KEY` and `INFURA_PROJECT_ID` are set correctly
     - Check that `NETWORK` matches your intended blockchain network
     - Ensure backend wallet has sufficient balance for gas fees
     - Verify Infura project ID is valid and has access to the selected network

5. **Privy operations failing**
   - **Solution**: 
     - Verify `PRIVY_APP_ID` and `PRIVY_APP_SECRET` are correct
     - Check that user IDs are valid Privy DIDs
     - Ensure proper permissions are set in Privy dashboard

## 📝 License

[Your License Here]

## 🤝 Contributing

[Contributing guidelines]

## 📞 Support

[Support information]

---

**Note**: This agent supports both CLI and Telegram interfaces. You can run either `main.py` for CLI or `telegram_bot.py` for Telegram, or both simultaneously if needed.
