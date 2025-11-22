"""Tools for the LangChain AI agent."""
from typing import Optional, Type
from langchain_core.tools import BaseTool, StructuredTool
from pydantic import BaseModel, Field
import requests


class WebSearchInput(BaseModel):
    """Input schema for web search tool."""
    query: str = Field(description="The search query to look up")


class CalculatorInput(BaseModel):
    """Input schema for calculator tool."""
    expression: str = Field(description="A mathematical expression to evaluate")


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
    ]
    
    return tools

