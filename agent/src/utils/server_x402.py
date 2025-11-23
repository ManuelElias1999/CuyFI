"""Mock X402 server client with mock data for testing."""
from typing import Optional, Dict, List
import time
import random


class ServerX402:
    """Mock client for X402 server with mock data."""
    
    def __init__(self, base_url: Optional[str] = None):
        """
        Initialize the X402 server client.
        
        Args:
            base_url: Base URL for the server (not used in mock, kept for compatibility)
        """
        self.base_url = base_url or "https://api.x402.example.com"
        self._mock_data = self._generate_mock_data()
    
    def _generate_mock_data(self) -> Dict:
        """Generate mock data for testing."""
        return {
            "streams": [
                {
                    "id": "stream_001",
                    "sender": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
                    "receiver": "0x8ba1f109551bD432803012645Hac136c22C9E8",
                    "amount": "1000000000000000000",  # 1 ETH in wei
                    "token_address": "0x0000000000000000000000000000000000000000",  # ETH
                    "start_time": int(time.time()) - 86400,  # 1 day ago
                    "end_time": int(time.time()) + 2592000,  # 30 days from now
                    "status": "active",
                    "rate_per_second": "38580246913580",  # ~1 ETH over 30 days
                    "withdrawn": "500000000000000000",  # 0.5 ETH
                    "remaining": "500000000000000000",  # 0.5 ETH
                },
                {
                    "id": "stream_002",
                    "sender": "0x8ba1f109551bD432803012645Hac136c22C9E8",
                    "receiver": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
                    "amount": "500000000",  # 500 USDC (6 decimals)
                    "token_address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",  # USDC
                    "start_time": int(time.time()) - 604800,  # 7 days ago
                    "end_time": int(time.time()) + 604800,  # 7 days from now
                    "status": "active",
                    "rate_per_second": "4133597883597",  # ~500 USDC over 14 days
                    "withdrawn": "250000000",  # 250 USDC
                    "remaining": "250000000",  # 250 USDC
                },
                {
                    "id": "stream_003",
                    "sender": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
                    "receiver": "0x1234567890123456789012345678901234567890",
                    "amount": "2000000000000000000",  # 2 ETH
                    "token_address": "0x0000000000000000000000000000000000000000",
                    "start_time": int(time.time()) - 172800,  # 2 days ago
                    "end_time": int(time.time()) - 86400,  # 1 day ago (ended)
                    "status": "completed",
                    "rate_per_second": "23148148148148",
                    "withdrawn": "2000000000000000000",  # 2 ETH (fully withdrawn)
                    "remaining": "0",
                },
            ],
            "tokens": [
                {
                    "address": "0x0000000000000000000000000000000000000000",
                    "symbol": "ETH",
                    "name": "Ethereum",
                    "decimals": 18,
                },
                {
                    "address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
                    "symbol": "USDC",
                    "name": "USD Coin",
                    "decimals": 6,
                },
                {
                    "address": "0xdAC17F958D2ee523a2206206994597C13D831ec7",
                    "symbol": "USDT",
                    "name": "Tether USD",
                    "decimals": 6,
                },
            ],
            "stats": {
                "total_streams": 3,
                "active_streams": 2,
                "completed_streams": 1,
                "total_volume_eth": "3.0",
                "total_volume_usd": "5000.0",
            },
        }
    
    def get_stream(self, stream_id: str) -> Optional[Dict]:
        """
        Get stream information by ID.
        
        Args:
            stream_id: The stream ID to retrieve
            
        Returns:
            Stream information if found, None otherwise
        """
        streams = self._mock_data["streams"]
        for stream in streams:
            if stream["id"] == stream_id:
                return stream.copy()
        return None
    
    def get_streams_by_address(self, address: str, role: str = "receiver") -> List[Dict]:
        """
        Get all streams for a given address.
        
        Args:
            address: Ethereum address
            role: "sender" or "receiver" (default: "receiver")
            
        Returns:
            List of streams
        """
        streams = self._mock_data["streams"]
        key = role if role == "sender" else "receiver"
        return [s.copy() for s in streams if s.get(key, "").lower() == address.lower()]
    
    def get_active_streams(self, address: Optional[str] = None) -> List[Dict]:
        """
        Get all active streams, optionally filtered by address.
        
        Args:
            address: Optional Ethereum address to filter by
            
        Returns:
            List of active streams
        """
        streams = self._mock_data["streams"]
        active = [s.copy() for s in streams if s["status"] == "active"]
        
        if address:
            active = [
                s for s in active
                if s["sender"].lower() == address.lower() or s["receiver"].lower() == address.lower()
            ]
        
        return active
    
    def create_stream(
        self,
        sender: str,
        receiver: str,
        amount: str,
        token_address: str,
        duration_seconds: int,
    ) -> Dict:
        """
        Create a new payment stream (mock).
        
        Args:
            sender: Sender Ethereum address
            receiver: Receiver Ethereum address
            amount: Amount in token's smallest unit (wei for ETH)
            token_address: Token contract address (0x0 for ETH)
            duration_seconds: Duration of the stream in seconds
            
        Returns:
            Created stream information
        """
        stream_id = f"stream_{random.randint(1000, 9999)}"
        current_time = int(time.time())
        
        new_stream = {
            "id": stream_id,
            "sender": sender,
            "receiver": receiver,
            "amount": amount,
            "token_address": token_address,
            "start_time": current_time,
            "end_time": current_time + duration_seconds,
            "status": "active",
            "rate_per_second": str(int(amount) // duration_seconds),
            "withdrawn": "0",
            "remaining": amount,
            "tx_hash": f"0x{''.join(random.choices('0123456789abcdef', k=64))}",
        }
        
        # Add to mock data
        self._mock_data["streams"].append(new_stream)
        self._mock_data["stats"]["total_streams"] += 1
        self._mock_data["stats"]["active_streams"] += 1
        
        return new_stream.copy()
    
    def cancel_stream(self, stream_id: str) -> Optional[Dict]:
        """
        Cancel a stream (mock).
        
        Args:
            stream_id: The stream ID to cancel
            
        Returns:
            Updated stream information if found, None otherwise
        """
        stream = self.get_stream(stream_id)
        if not stream:
            return None
        
        stream["status"] = "cancelled"
        stream["end_time"] = int(time.time())
        
        # Update in mock data
        for s in self._mock_data["streams"]:
            if s["id"] == stream_id:
                s["status"] = "cancelled"
                s["end_time"] = int(time.time())
                break
        
        self._mock_data["stats"]["active_streams"] = max(0, self._mock_data["stats"]["active_streams"] - 1)
        
        return stream
    
    def withdraw_from_stream(self, stream_id: str, amount: Optional[str] = None) -> Dict:
        """
        Withdraw from a stream (mock).
        
        Args:
            stream_id: The stream ID to withdraw from
            amount: Optional amount to withdraw (defaults to available amount)
            
        Returns:
            Withdrawal transaction information
        """
        stream = self.get_stream(stream_id)
        if not stream:
            return {"error": "Stream not found"}
        
        if stream["status"] != "active":
            return {"error": f"Stream is {stream['status']}, cannot withdraw"}
        
        # Calculate available amount (simplified mock)
        available = int(stream["remaining"])
        withdraw_amount = int(amount) if amount else available
        
        if withdraw_amount > available:
            withdraw_amount = available
        
        # Update stream
        for s in self._mock_data["streams"]:
            if s["id"] == stream_id:
                s["withdrawn"] = str(int(s["withdrawn"]) + withdraw_amount)
                s["remaining"] = str(int(s["remaining"]) - withdraw_amount)
                if int(s["remaining"]) == 0:
                    s["status"] = "completed"
                break
        
        return {
            "stream_id": stream_id,
            "amount": str(withdraw_amount),
            "tx_hash": f"0x{''.join(random.choices('0123456789abcdef', k=64))}",
            "timestamp": int(time.time()),
            "status": "success",
        }
    
    def get_token_info(self, token_address: str) -> Optional[Dict]:
        """
        Get token information.
        
        Args:
            token_address: Token contract address
            
        Returns:
            Token information if found, None otherwise
        """
        tokens = self._mock_data["tokens"]
        for token in tokens:
            if token["address"].lower() == token_address.lower():
                return token.copy()
        return None
    
    def get_stats(self) -> Dict:
        """
        Get server statistics.
        
        Returns:
            Statistics dictionary
        """
        return self._mock_data["stats"].copy()
    
    def get_available_balance(self, address: str, token_address: str) -> str:
        """
        Get available balance for withdrawal from streams.
        
        Args:
            address: Ethereum address
            token_address: Token contract address
            
        Returns:
            Available balance as string
        """
        streams = self.get_streams_by_address(address, role="receiver")
        total = 0
        
        for stream in streams:
            if stream["token_address"].lower() == token_address.lower() and stream["status"] == "active":
                total += int(stream["remaining"])
        
        return str(total)

