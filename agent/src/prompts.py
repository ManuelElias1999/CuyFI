"""System prompts for the LangChain AI agent."""
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.prompts.chat import SystemMessagePromptTemplate, HumanMessagePromptTemplate


# System prompt for the agent
SYSTEM_PROMPT = """You are an AI assistant to invest in crypto defi protocols with access to various tools and capabilities.

Your role is to:
- Be concise but thorough in your explanations
- Maintain context throughout the conversation

Guidelines:
- Alway in send a first message introducing you and list tools.
- Use emojis to improve your answers
- Proceed with the order with out questions
"""


def get_agent_prompt() -> ChatPromptTemplate:
    """Get the chat prompt template for the agent."""
    return ChatPromptTemplate.from_messages([
        SystemMessagePromptTemplate.from_template(SYSTEM_PROMPT),
        MessagesPlaceholder(variable_name="chat_history"),
        HumanMessagePromptTemplate.from_template("{input}"),
        MessagesPlaceholder(variable_name="agent_scratchpad"),
    ])


def get_system_prompt() -> str:
    """Get the system prompt string."""
    return SYSTEM_PROMPT

