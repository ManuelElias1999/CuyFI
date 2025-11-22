"""Telegram bot entry point for the LangChain AI agent."""
import logging
import sys
from typing import Optional

from telegram import Update
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    ContextTypes,
    filters,
)

from src.agent import LangChainAgent
from src.config import Config

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)


class TelegramBot:
    """Telegram bot wrapper for the LangChain agent."""
    
    def __init__(self, bot_token: str, channel_id: Optional[str] = None):
        """
        Initialize the Telegram bot.
        
        Args:
            bot_token: Telegram bot token from BotFather
            channel_id: Optional channel ID for broadcasting messages
        """
        self.bot_token = bot_token
        self.channel_id = channel_id
        self.agent: Optional[LangChainAgent] = None
        self.application: Optional[Application] = None
        
    def initialize_agent(self):
        """Initialize the LangChain agent."""
        try:
            logger.info("Initializing LangChain agent...")
            self.agent = LangChainAgent(
                verbose=Config.AGENT_VERBOSE,
                max_iterations=Config.AGENT_MAX_ITERATIONS,
            )
            logger.info("Agent initialized successfully!")
        except Exception as e:
            logger.error(f"Failed to initialize agent: {str(e)}")
            raise
    
    async def start_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle the /start command."""
        welcome_message = (
            "🤖 Welcome to CuyFi Agent!\n\n"
            "I'm here to help you. You can:\n"
            "• Ask me questions\n"
            "• Request information\n"
            "• Use /help to see available commands\n\n"
            "Just send me a message and I'll respond!"
        )
        await update.message.reply_text(welcome_message)
    
    async def help_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle the /help command."""
        help_message = (
            "📚 Available Commands:\n\n"
            "/start - Start the bot and see welcome message\n"
            "/help - Show this help message\n"
            "/clear - Clear conversation history\n"
            "/status - Check bot status\n\n"
            "You can also just send me a message and I'll respond!"
        )
        await update.message.reply_text(help_message)
    
    async def clear_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle the /clear command to reset conversation history."""
        if self.agent:
            self.agent.clear_memory()
            await update.message.reply_text("✅ Conversation history cleared!")
        else:
            await update.message.reply_text("❌ Agent not initialized.")
    
    async def status_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle the /status command."""
        status_message = (
            f"🤖 Bot Status:\n\n"
            f"• Agent: {'✅ Active' if self.agent else '❌ Not initialized'}\n"
            f"• Model: {Config.OPENAI_MODEL}\n"
            f"• Channel ID: {self.channel_id or 'Not configured'}\n"
        )
        await update.message.reply_text(status_message)
    
    async def handle_message(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle incoming text messages."""
        if not self.agent:
            await update.message.reply_text(
                "❌ Agent not initialized. Please check the bot configuration."
            )
            return
        
        user_message = update.message.text
        user_id = update.effective_user.id
        username = update.effective_user.username or "Unknown"
        
        logger.info(f"Received message from {username} ({user_id}): {user_message}")
        
        # Show typing indicator
        await context.bot.send_chat_action(
            chat_id=update.effective_chat.id,
            action="typing"
        )
        
        try:
            # Get agent response
            response = self.agent.run(user_message)
            
            # Send response
            await update.message.reply_text(response)
            
            logger.info(f"Sent response to {username} ({user_id})")
            
        except Exception as e:
            error_message = f"❌ Error processing your message: {str(e)}"
            await update.message.reply_text(error_message)
            logger.error(f"Error handling message: {str(e)}", exc_info=True)
    
    async def post_to_channel(self, message: str) -> bool:
        """
        Post a message to the configured Telegram channel.
        
        Args:
            message: The message to post
            
        Returns:
            True if successful, False otherwise
        """
        if not self.channel_id:
            logger.warning("Channel ID not configured. Cannot post to channel.")
            return False
        
        if not self.application:
            logger.warning("Application not initialized. Cannot post to channel.")
            return False
        
        try:
            await self.application.bot.send_message(
                chat_id=self.channel_id,
                text=message
            )
            logger.info(f"Posted message to channel {self.channel_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to post to channel: {str(e)}")
            return False
    
    def setup_handlers(self, application: Application):
        """Set up command and message handlers."""
        # Command handlers
        application.add_handler(CommandHandler("start", self.start_command))
        application.add_handler(CommandHandler("help", self.help_command))
        application.add_handler(CommandHandler("clear", self.clear_command))
        application.add_handler(CommandHandler("status", self.status_command))
        
        # Message handler (must be last to catch all text messages)
        application.add_handler(
            MessageHandler(filters.TEXT & ~filters.COMMAND, self.handle_message)
        )
    
    async def post_init(self, application: Application):
        """Post-initialization callback."""
        logger.info("Telegram bot is ready and running!")
        if self.channel_id:
            try:
                await application.bot.send_message(
                    chat_id=self.channel_id,
                    text="🤖 Bot is now online and ready to receive messages!"
                )
            except Exception as e:
                logger.warning(f"Could not send startup message to channel: {str(e)}")
    
    def run(self):
        """Run the Telegram bot."""
        try:
            # Validate configuration
            Config.validate()
            
            if not self.bot_token:
                raise ValueError("TELEGRAM_BOT_TOKEN is required. Please set it in your .env file.")
            
            # Initialize agent
            self.initialize_agent()
            
            # Create application with post_init callback
            self.application = (
                Application.builder()
                .token(self.bot_token)
                .post_init(self.post_init)
                .build()
            )
            
            # Set up handlers
            self.setup_handlers(self.application)
            
            # Start the bot
            logger.info("Starting Telegram bot...")
            self.application.run_polling(allowed_updates=Update.ALL_TYPES)
            
        except ValueError as e:
            logger.error(f"Configuration error: {str(e)}")
            sys.exit(1)
        except Exception as e:
            logger.error(f"Fatal error: {str(e)}", exc_info=True)
            sys.exit(1)


def main():
    """Main function to run the Telegram bot."""
    # Get configuration
    bot_token = Config.TELEGRAM_BOT_TOKEN
    channel_id = Config.TELEGRAM_CHANNEL_ID
    
    # Create and run bot
    bot = TelegramBot(bot_token=bot_token, channel_id=channel_id)
    bot.run()


if __name__ == "__main__":
    main()

