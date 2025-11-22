# LangChain AI Agent

A base project structure for a LangChain AI agent with OpenAI integration.

## Project Structure

```
agent/
├── main.py                 # Entry point for the agent
├── requirements.txt        # Python dependencies
├── .env.example           # Example environment variables
├── .gitignore            # Git ignore rules
└── src/
    ├── __init__.py       # Package initialization
    ├── agent.py          # Main agent implementation
    ├── config.py         # Configuration management
    ├── prompts.py        # System prompts
    ├── tools.py          # Agent tools
    └── privy_client.py   # Privy authentication client
```

## Setup

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Create a `.env` file:**
   ```bash
   cp .env.example .env
   ```

3. **Configure your environment variables:**
   - `OPENAI_API_KEY`: Your OpenAI API key (required)
   - `OPENAI_MODEL`: Model to use (default: gpt-4-turbo-preview)
   - `OPENAI_TEMPERATURE`: Model temperature (default: 0.7)
   - `AGENT_VERBOSE`: Enable verbose output (default: False)
   - `AGENT_MAX_ITERATIONS`: Maximum agent iterations (default: 15)

## Usage

### Running the Agent

```bash
python main.py
```

This will start an interactive chat session with the agent.

### Using the Agent Programmatically

```python
from src.agent import LangChainAgent

# Initialize the agent
agent = LangChainAgent()

# Run a query
response = agent.run("What is the capital of France?")
print(response)

# Chat with the agent
response = agent.chat("Tell me a joke")
print(response)

# Clear conversation memory
agent.clear_memory()
```

## Features

- **OpenAI Integration**: Uses OpenAI's GPT models via LangChain
- **Tool Support**: Includes web search and calculator tools
- **Conversation Memory**: Maintains context across interactions
- **Configurable**: Easy configuration via environment variables
- **Extensible**: Easy to add custom tools and prompts

## Adding Custom Tools

To add custom tools, edit `src/tools.py`:

```python
def my_custom_tool(input: str) -> str:
    """Description of what the tool does."""
    # Your tool logic here
    return result

def get_tools() -> list[BaseTool]:
    tools = [
        # ... existing tools ...
        StructuredTool.from_function(
            func=my_custom_tool,
            name="my_custom_tool",
            description="Description for the agent",
        ),
    ]
    return tools
```

## Customizing Prompts

Edit `src/prompts.py` to customize the system prompt and agent behavior.

## License

[Your License Here]

