"""Privy client for authentication and user management."""
from typing import Optional
import base64
import requests
from ..config import Config


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
    
    def create_embedded_wallet(self, user_id: str, chain_type: str = "ethereum", create_smart_wallet: bool = True) -> Optional[dict]:
        """
        Create an embedded wallet for a user.
        
        Args:
            user_id: The Privy user ID
            chain_type: Type of chain for the wallet (default: "ethereum")
            create_smart_wallet: Whether to create a smart wallet (default: True)
            
        Returns:
            Wallet information if created successfully, None otherwise
        """
        if not self.app_secret:
            raise ValueError("PRIVY_APP_SECRET is required for wallet creation")
        if not self.app_id:
            raise ValueError("PRIVY_APP_ID is required for wallet creation")
        
        try:
            # Create Basic auth header: base64(app_id:app_secret)
            credentials = f"{self.app_id}:{self.app_secret}"
            encoded_credentials = base64.b64encode(credentials.encode()).decode()
            
            headers = {
                "Authorization": f"Basic {encoded_credentials}",
                "Content-Type": "application/json",
                "privy-app-id": self.app_id,
            }
            
            # Use the correct API endpoint for wallet creation
            api_url = "https://api.privy.io/v1"
            response = requests.post(
                f"{api_url}/users/{user_id}/wallets",
                headers=headers,
                json={
                    "wallets": [
                        {
                            "chain_type": chain_type,
                            "create_smart_wallet": create_smart_wallet
                        }
                    ]
                },
                timeout=10,
            )
            
            if response.status_code in (200, 201):
                return response.json()
            elif response.status_code == 400:
                error_data = response.json()
                error_msg = error_data.get("error", {}).get("message", "Bad request")
                raise ValueError(f"Failed to create wallet: {error_msg}")
            else:
                error_data = response.json() if response.content else {}
                error_msg = error_data.get("error", {}).get("message", f"HTTP {response.status_code}")
                raise ValueError(f"Failed to create wallet: {error_msg}")
        except requests.exceptions.RequestException as e:
            print(f"Error creating embedded wallet: {str(e)}")
            raise
        except Exception as e:
            print(f"Error creating embedded wallet: {str(e)}")
            raise

