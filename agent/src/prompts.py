"""System prompts for the LangChain AI agent."""
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.prompts.chat import SystemMessagePromptTemplate, HumanMessagePromptTemplate


# System prompt for the agent
SYSTEM_PROMPT = """You are a helpful AI assistant with access to various tools and capabilities.

Your role is to:
- Understand user queries and provide accurate, helpful responses
- Use available tools when appropriate to gather information or perform actions
- Be concise but thorough in your explanations
- Ask clarifying questions when needed
- Maintain context throughout the conversation

Guidelines:
- Always think step by step before taking action
- If you're unsure about something, ask for clarification
- Use tools efficiently and only when necessary
- Provide clear explanations of your actions and reasoning
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

