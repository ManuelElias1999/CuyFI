# LangChain AI Agent with Telegram Integration

A powerful LangChain-based AI agent with OpenAI integration, Web3 capabilities, and Telegram bot support. This agent can interact with users via command-line interface or Telegram, perform web searches, execute DeFi operations, and manage cryptocurrency wallets.

## 🚀 Features

### Core Capabilities
- **OpenAI Integration**: Uses OpenAI's GPT models (GPT-4 Turbo) via LangChain
- **Conversation Memory**: Maintains context across interactions
- **Multi-Interface Support**: Available via CLI and Telegram bot
- **Tool-Based Architecture**: Extensible tool system for adding new capabilities

### Available Tools

1. **Web Search** 🔍
   - Search the web for current information
   - Uses DuckDuckGo API for search results
   - Perfect for queries requiring up-to-date information

2. **Calculator** 🧮
   - Evaluate mathematical expressions safely
   - Supports basic arithmetic operations
   - Safe evaluation with input validation

3. **Wallet Management** 💼
   - **Get Balance**: Check ETH balance of any Ethereum address
   - **Create Embedded Wallet**: Create Privy embedded wallets for users
   - Supports backend wallet operations

4. **DeFi Operations** 🌐
   - **Supply to Aave**: Supply tokens to Aave V3 Pool on Polygon
   - Automatic token approval handling
   - Support for USDC, USDT, WETH, and other assets
   - Transaction tracking with explorer links

5. **Smart Wallet Operations** 🔐
   - **Send ETH**: Prepare ETH transfers from Privy Smart Wallets
   - Integration with Privy authentication system
   - Secure transaction preparation

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
You: What is 25 * 47?
Agent: 1175

You: Search for the latest news about Ethereum
Agent: [Performs web search and returns results]

You: Check the balance of 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
Agent: [Returns balance information]
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

### Optional Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_MODEL` | OpenAI model to use | `gpt-4-turbo-preview` |
| `OPENAI_TEMPERATURE` | Model temperature (0-1) | `0.7` |
| `AGENT_VERBOSE` | Enable verbose output | `False` |
| `AGENT_MAX_ITERATIONS` | Max agent iterations | `15` |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token | - |
| `TELEGRAM_CHANNEL_ID` | Telegram channel ID | - |
| `PRIVY_APP_ID` | Privy application ID | - |
| `PRIVY_APP_SECRET` | Privy application secret | - |
| `WEB3_RPC_URL` | Web3 RPC endpoint | - |
| `CHAIN_ID` | Blockchain chain ID | `1` |

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

#### Supply to Aave
Supply tokens to Aave V3 Pool on Polygon:
```
You: Supply 100 USDC to Aave
```

The agent will:
- Automatically approve token spending if needed
- Execute the supply transaction
- Return transaction hash and explorer link

**Supported Assets:**
- USDC (6 decimals)
- USDT (6 decimals)
- WETH (18 decimals)
- Other ERC-20 tokens

#### Create Embedded Wallet
Create a Privy embedded wallet for a user:
```
You: Create an embedded wallet for user did:privy:abc123
```

#### Send ETH from Smart Wallet
Prepare ETH transfer from a Privy Smart Wallet:
```
You: Send 0.1 ETH from user did:privy:abc123 to 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
```

**Note:** This prepares the transaction. Actual signing and sending requires Privy's transaction API or frontend SDK.

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
     - Verify `WEB3_RPC_URL` is correct and accessible
     - Check that `CHAIN_ID` matches your network
     - Ensure wallet has sufficient balance for gas fees

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
