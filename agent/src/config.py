"""Configuration management for the LangChain AI agent."""
import os
from typing import Optional
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class Config:
    """Configuration class for managing environment variables."""
    
    # OpenAI Configuration
    OPENAI_API_KEY: Optional[str] = os.getenv("OPENAI_API_KEY")
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-4-turbo-preview")
    OPENAI_TEMPERATURE: float = float(os.getenv("OPENAI_TEMPERATURE", "0.7"))
    
    # Privy Configuration (if needed)
    PRIVY_APP_ID: Optional[str] = os.getenv("PRIVY_APP_ID")
    PRIVY_APP_SECRET: Optional[str] = os.getenv("PRIVY_APP_SECRET")
    
    # Agent Configuration
    AGENT_VERBOSE: bool = os.getenv("AGENT_VERBOSE", "False").lower() == "true"
    AGENT_MAX_ITERATIONS: int = int(os.getenv("AGENT_MAX_ITERATIONS", "15"))
    
    # Web3 Configuration (if needed)
    WEB3_RPC_URL: Optional[str] = os.getenv("WEB3_RPC_URL")
    CHAIN_ID: Optional[int] = int(os.getenv("CHAIN_ID", "1")) if os.getenv("CHAIN_ID") else None
    
    @classmethod
    def validate(cls) -> bool:
        """Validate that required configuration is present."""
        if not cls.OPENAI_API_KEY:
            raise ValueError("OPENAI_API_KEY is required. Please set it in your .env file.")
        return True

