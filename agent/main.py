"""Main entry point for the LangChain AI agent."""
import sys
from src.agent import LangChainAgent
from src.config import Config


def main():
    """Main function to run the agent."""
    try:
        # Validate configuration
        Config.validate()
        
        # Initialize agent
        print("Initializing LangChain agent...")
        agent = LangChainAgent(
            verbose=Config.AGENT_VERBOSE,
            max_iterations=Config.AGENT_MAX_ITERATIONS,
        )
        
        print("Agent initialized successfully!")
        print("Type 'exit' or 'quit' to end the conversation.\n")
        
        # Interactive loop
        while True:
            try:
                # Get user input
                user_input = input("You: ").strip()
                
                # Check for exit commands
                if user_input.lower() in ["exit", "quit", "q"]:
                    print("Goodbye!")
                    break
                
                # Skip empty inputs
                if not user_input:
                    continue
                
                # Get agent response
                response = agent.run(user_input)
                print(f"Agent: {response}\n")
                
            except KeyboardInterrupt:
                print("\n\nInterrupted by user. Goodbye!")
                break
            except Exception as e:
                print(f"Error: {str(e)}\n")
                
    except ValueError as e:
        print(f"Configuration error: {str(e)}")
        print("Please make sure you have set OPENAI_API_KEY in your .env file.")
        sys.exit(1)
    except Exception as e:
        print(f"Fatal error: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()

