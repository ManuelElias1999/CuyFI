"""Main LangChain agent implementation."""
from typing import Optional, List
from langchain_classic.agents import AgentExecutor, create_openai_tools_agent
from langchain_openai import ChatOpenAI
from langchain_classic.memory import ConversationBufferMemory
from langchain_core.messages import BaseMessage

from .config import Config
from .prompts import get_agent_prompt
from .tools import get_tools


class LangChainAgent:
    """Main LangChain agent class."""
    
    def __init__(
        self,
        model_name: Optional[str] = None,
        temperature: Optional[float] = None,
        verbose: Optional[bool] = None,
        max_iterations: Optional[int] = None,
    ):
        """
        Initialize the LangChain agent.
        
        Args:
            model_name: OpenAI model name (defaults to Config.OPENAI_MODEL)
            temperature: Model temperature (defaults to Config.OPENAI_TEMPERATURE)
            verbose: Whether to print verbose output (defaults to Config.AGENT_VERBOSE)
            max_iterations: Maximum agent iterations (defaults to Config.AGENT_MAX_ITERATIONS)
        """
        # Validate configuration
        Config.validate()
        
        # Set parameters
        self.model_name = model_name or Config.OPENAI_MODEL
        self.temperature = temperature if temperature is not None else Config.OPENAI_TEMPERATURE
        self.verbose = verbose if verbose is not None else Config.AGENT_VERBOSE
        self.max_iterations = max_iterations or Config.AGENT_MAX_ITERATIONS
        
        # Initialize LLM
        self.llm = ChatOpenAI(
            model=self.model_name,
            temperature=self.temperature,
            openai_api_key=Config.OPENAI_API_KEY,
        )
        
        # Get tools and prompt
        self.tools = get_tools()
        self.prompt = get_agent_prompt()
        
        # Create agent
        self.agent = create_openai_tools_agent(
            llm=self.llm,
            tools=self.tools,
            prompt=self.prompt,
        )
        
        # Initialize memory
        self.memory = ConversationBufferMemory(
            memory_key="chat_history",
            return_messages=True,
        )
        
        # Create agent executor
        self.agent_executor = AgentExecutor(
            agent=self.agent,
            tools=self.tools,
            memory=self.memory,
            verbose=self.verbose,
            max_iterations=self.max_iterations,
            handle_parsing_errors=True,
        )
    
    def run(self, input_text: str) -> str:
        """
        Run the agent with a given input.
        
        Args:
            input_text: The user's input text
            
        Returns:
            The agent's response
        """
        try:
            result = self.agent_executor.invoke({"input": input_text})
            return result.get("output", "No response generated")
        except Exception as e:
            return f"Error: {str(e)}"
    
    def chat(self, message: str) -> str:
        """
        Chat with the agent (alias for run method).
        
        Args:
            message: The user's message
            
        Returns:
            The agent's response
        """
        return self.run(message)
    
    def clear_memory(self):
        """Clear the conversation memory."""
        self.memory.clear()
    
    def get_chat_history(self) -> List[BaseMessage]:
        """
        Get the current chat history.
        
        Returns:
            List of messages in the conversation
        """
        return self.memory.chat_memory.messages

