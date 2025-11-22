"""Privy client for authentication and user management."""
from typing import Optional
import requests
from .config import Config


class PrivyClient:
    """Client for interacting with Privy API."""
    
    def __init__(
        self,
        app_id: Optional[str] = None,
        app_secret: Optional[str] = None,
    ):
        """
        Initialize the Privy client.
        
        Args:
            app_id: Privy app ID (defaults to Config.PRIVY_APP_ID)
            app_secret: Privy app secret (defaults to Config.PRIVY_APP_SECRET)
        """
        self.app_id = app_id or Config.PRIVY_APP_ID
        self.app_secret = app_secret or Config.PRIVY_APP_SECRET
        self.base_url = "https://auth.privy.io/api/v1"
    
    def verify_token(self, token: str) -> Optional[dict]:
        """
        Verify a Privy authentication token.
        
        Args:
            token: The authentication token to verify
            
        Returns:
            User information if token is valid, None otherwise
        """
        if not self.app_secret:
            raise ValueError("PRIVY_APP_SECRET is required for token verification")
        
        try:
            headers = {
                "Authorization": f"Bearer {self.app_secret}",
                "Content-Type": "application/json",
            }
            response = requests.post(
                f"{self.base_url}/tokens/verify",
                headers=headers,
                json={"token": token},
                timeout=10,
            )
            
            if response.status_code == 200:
                return response.json()
            return None
        except Exception as e:
            print(f"Error verifying token: {str(e)}")
            return None
    
    def get_user(self, user_id: str) -> Optional[dict]:
        """
        Get user information by user ID.
        
        Args:
            user_id: The Privy user ID
            
        Returns:
            User information if found, None otherwise
        """
        if not self.app_secret:
            raise ValueError("PRIVY_APP_SECRET is required for user lookup")
        
        try:
            headers = {
                "Authorization": f"Bearer {self.app_secret}",
                "Content-Type": "application/json",
            }
            response = requests.get(
                f"{self.base_url}/users/{user_id}",
                headers=headers,
                timeout=10,
            )
            
            if response.status_code == 200:
                return response.json()
            return None
        except Exception as e:
            print(f"Error getting user: {str(e)}")
            return None

