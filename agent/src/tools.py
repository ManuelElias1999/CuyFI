"""Tools for the LangChain AI agent."""
from typing import Optional, Type
from langchain_core.tools import BaseTool, StructuredTool
from pydantic import BaseModel, Field
import requests
import base64
from web3 import Web3
from .utils.privy_client import PrivyClient
from .utils.wallet_manager import create_wallet_from_env
from .config import Config


class WebSearchInput(BaseModel):
    """Input schema for web search tool."""
    query: str = Field(description="The search query to look up")


class CalculatorInput(BaseModel):
    """Input schema for calculator tool."""
    expression: str = Field(description="A mathematical expression to evaluate")


class CreateEmbeddedWalletInput(BaseModel):
    """Input schema for create embedded wallet tool."""
    user_id: str = Field(description="The Privy user ID for which to create an embedded wallet")
    wallet_type: Optional[str] = Field(
        default="ethereum",
        description="Type of wallet to create (default: 'ethereum')"
    )


class SendEthFromSmartWalletInput(BaseModel):
    """Input schema for send ETH from smart wallet tool."""
    user_id: str = Field(description="The Privy user ID (DID) of the user, e.g., 'did:privy:cmi9k8qqw0281jy0cygoeasbt'")
    to_address: str = Field(description="The destination Ethereum address to send ETH to")
    amount_eth: float = Field(description="The amount of ETH to send (e.g., 0.1)")


class GetBalanceInput(BaseModel):
    """Input schema for get balance tool."""
    address: Optional[str] = Field(
        default=None,
        description="The Ethereum address to check balance for. If not provided, uses the backend wallet address."
    )


def web_search(query: str) -> str:
    """
    Search the web for information about a given query.
    
    Args:
        query: The search query
        
    Returns:
        A string containing search results or information
    """
    # This is a placeholder - you can integrate with a real search API
    # For example: Serper, Tavily, or DuckDuckGo
    try:
        print('=> Query:', query)
        # Example: Using DuckDuckGo (you may want to use a proper API)
        response = requests.get(
            f"https://api.duckduckgo.com/?q={query}&format=json&no_html=1&skip_disambig=1",
            timeout=5
        )
        if response.status_code == 200:
            data = response.json()
            results = data.get("AbstractText", "No results found")
            return results
        return "Search service unavailable"
    except Exception as e:
        return f"Error performing search: {str(e)}"


def calculator(expression: str) -> str:
    """
    Evaluate a mathematical expression safely.
    
    Args:
        expression: A mathematical expression (e.g., "2 + 2", "10 * 5")
        
    Returns:
        The result of the calculation
    """
    try:
        # Safe evaluation - only allow basic math operations
        allowed_chars = set("0123456789+-*/()., ")
        if not all(c in allowed_chars for c in expression):
            return "Error: Invalid characters in expression"
        
        result = eval(expression)
        return str(result)
    except Exception as e:
        return f"Error calculating: {str(e)}"


def create_embedded_wallet(user_id: str, wallet_type: str = "ethereum") -> str:
    """
    Create an embedded wallet for a Privy user.
    
    Args:
        user_id: The Privy user ID for which to create an embedded wallet
        wallet_type: Type of wallet to create (default: "ethereum")
        
    Returns:
        A string containing the wallet information or error message
    """
    try:
        privy_client = PrivyClient()
        result = privy_client.create_embedded_wallet(user_id, wallet_type)
        
        if result:
            wallet_address = result.get("address", "N/A")
            wallet_id = result.get("id", "N/A")
            return f"Successfully created embedded wallet for user {user_id}. Wallet ID: {wallet_id}, Address: {wallet_address}"
        else:
            return f"Failed to create embedded wallet for user {user_id}"
    except ValueError as e:
        return f"Error: {str(e)}"
    except Exception as e:
        return f"Error creating embedded wallet: {str(e)}"


def send_eth_from_smart_wallet(user_id: str, to_address: str, amount_eth: float) -> str:
    """
    Send ETH from a user's Smart Wallet.
    
    Args:
        user_id: DID of the user (e.g., 'did:privy:cmi9k8qqw0281jy0cygoeasbt')
        to_address: Destination Ethereum address
        amount_eth: Amount in ETH (e.g., 0.1)
        
    Returns:
        A string containing transaction information or error message
    """
    try:
        # Validate configuration
        if not Config.PRIVY_APP_ID:
            return "Error: PRIVY_APP_ID is not configured"
        if not Config.PRIVY_APP_SECRET:
            return "Error: PRIVY_APP_SECRET is not configured"
        if not Config.WEB3_RPC_URL:
            return "Error: WEB3_RPC_URL is not configured"
        
        # Initialize Web3
        w3 = Web3(Web3.HTTPProvider(Config.WEB3_RPC_URL))
        if not w3.is_connected():
            return "Error: Failed to connect to Ethereum RPC provider"
        
        # Prepare Basic Auth credentials for Privy
        credentials = f"{Config.PRIVY_APP_ID}:{Config.PRIVY_APP_SECRET}"
        encoded_credentials = base64.b64encode(credentials.encode()).decode()
        
        # 1. Get user information
        headers = {
            'Authorization': f'Basic {encoded_credentials}',
            'privy-app-id': Config.PRIVY_APP_ID,
            'Content-Type': 'application/json'
        }
        
        response = requests.get(
            f'https://api.privy.io/v1/users/{user_id}',
            headers=headers,
            timeout=10
        )
        
        if response.status_code != 200:
            return f"Error: Failed to get user information. Status: {response.status_code}, Message: {response.text}"
        
        user = response.json()
        
        # 2. Find the Smart Wallet
        smart_wallet = None
        linked_accounts = user.get('linked_accounts', [])
        for account in linked_accounts:
            if account.get('type') == 'smart_wallet':
                smart_wallet = account
                break
        
        if not smart_wallet:
            return f"Error: Smart Wallet not found for user {user_id}"
        
        smart_wallet_address = smart_wallet.get('address')
        if not smart_wallet_address:
            return "Error: Smart wallet address not found"
        
        # 3. Prepare transaction
        chain_id = Config.CHAIN_ID or 1  # Default to mainnet
        
        tx = {
            'from': smart_wallet_address,
            'to': to_address,
            'value': w3.to_wei(amount_eth, 'ether'),
            'gas': 21000,
            'gasPrice': w3.eth.gas_price,
            'nonce': w3.eth.get_transaction_count(smart_wallet_address),
            'chainId': chain_id
        }
        
        # Note: Privy doesn't expose private keys directly for security reasons
        # The transaction needs to be signed using Privy's transaction API or frontend
        # This function prepares the transaction but cannot sign/send it without additional Privy API support
        
        return (
            f"Transaction prepared successfully.\n"
            f"Smart Wallet: {smart_wallet_address}\n"
            f"To: {to_address}\n"
            f"Amount: {amount_eth} ETH ({tx['value']} wei)\n"
            f"Gas: {tx['gas']}\n"
            f"Gas Price: {tx['gasPrice']} wei\n"
            f"Nonce: {tx['nonce']}\n"
            f"Chain ID: {chain_id}\n"
            f"\nNote: This transaction needs to be signed and sent using Privy's transaction API or frontend SDK, "
            f"as Privy does not expose private keys directly for security reasons."
        )
        
    except ValueError as e:
        print("error:", e)
        return f"Error: {str(e)}"
    except requests.exceptions.RequestException as e:
        print("error:", e)
        return f"Error: Failed to communicate with Privy API: {str(e)}"
    except Exception as e:
        print("error:", e)
        return f"Error sending ETH from smart wallet: {str(e)}"


def get_balance(address: Optional[str] = None) -> str:
    """
    Get the ETH balance of an Ethereum address using the wallet manager.
    
    Args:
        address: The Ethereum address to check balance for. If not provided, uses the backend wallet address.
        
    Returns:
        A string containing the balance information in ETH and Wei
    """
    try:
        print("=> start: ok")
        wallet_manager = create_wallet_from_env()
        print("=> wallet_manager:", wallet_manager)
        balance_info = wallet_manager.get_balance(address)
        
        return (
            f"Balance Information:\n"
            f"Address: {balance_info['address']}\n"
            f"Balance: {balance_info['balance_eth']} ETH\n"
            f"Balance (Wei): {balance_info['balance_wei']}\n"
            f"Network: {balance_info['network']}"
        )
    except ValueError as e:
        return f"Error: {str(e)}"
    except Exception as e:
        return f"Error getting balance: {str(e)}"


def get_tools() -> list[BaseTool]:
    """
    Get a list of available tools for the agent.
    
    Returns:
        A list of LangChain tools
    """
    tools = [
        StructuredTool.from_function(
            func=web_search,
            name="web_search",
            description="Search the web for information about a given query. Use this when you need current information or facts that you don't have in your training data.",
            args_schema=WebSearchInput,
        ),
        StructuredTool.from_function(
            func=calculator,
            name="calculator",
            description="Evaluate a mathematical expression. Use this for any mathematical calculations.",
            args_schema=CalculatorInput,
        ),
        StructuredTool.from_function(
            func=create_embedded_wallet,
            name="create_embedded_wallet",
            description="Create an embedded wallet for a Privy user. Use this when a user needs a new embedded wallet created. Requires a Privy user ID.",
            args_schema=CreateEmbeddedWalletInput,
        ),
        StructuredTool.from_function(
            func=send_eth_from_smart_wallet,
            name="send_eth_from_smart_wallet",
            description="Send ETH from a user's Smart Wallet to another address. Use this when a user wants to transfer ETH from their Privy smart wallet. Requires the user's Privy user ID (DID), destination address, and amount in ETH. Note: This prepares the transaction but requires Privy's transaction API or frontend SDK to sign and send it.",
            args_schema=SendEthFromSmartWalletInput,
        ),
        StructuredTool.from_function(
            func=get_balance,
            name="get_balance",
            description="Get the ETH balance of an Ethereum address using the wallet manager. Use this when you need to check the balance of a wallet address. If no address is provided, it will check the backend wallet balance.",
            args_schema=GetBalanceInput,
        ),
    ]
    
    return tools

