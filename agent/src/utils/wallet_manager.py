import os
from typing import Optional, Dict, Any

from dotenv import load_dotenv
from eth_account import Account
from web3 import Web3

# Cargar variables de entorno
load_dotenv()


class WalletManager:
    """
    Wallet del backend con control total
    Firma transacciones desde Python usando Infura
    """

    def __init__(
        self,
        private_key: str,
        infura_project_id: str,
        network: str = 'mainnet'
    ):
        """
        Inicializar wallet del backend

        Args:
            private_key: Private key de la wallet del backend
            infura_project_id: Project ID de Infura
            network: Red a usar (mainnet, sepolia, polygon, etc)
        """
        # Configurar red
        self.network = network
        infura_url = self._get_infura_url(network, infura_project_id)

        # Conectar a Infura
        self.w3 = Web3(Web3.HTTPProvider(infura_url))

        # Verificar conexión
        if not self.w3.is_connected():
            raise ConnectionError(f"No se pudo conectar a Infura ({network})")

        print(f"✅ Conectado a {network} via Infura")

        # Cargar cuenta
        self.account = Account.from_key(private_key)
        self.address = self.account.address

        print(f"📍 Wallet Address: {self.address}")

    def _get_infura_url(self, network: str, project_id: str) -> str:
        """Obtener URL de Infura según la red"""
        urls = {
            'mainnet': f'https://mainnet.infura.io/v3/{project_id}',
            'sepolia': f'https://sepolia.infura.io/v3/{project_id}',
            'polygon': f'https://polygon-mainnet.infura.io/v3/{project_id}',
            'polygon-amoy': f'https://polygon-amoy.infura.io/v3/{project_id}',
            'arbitrum': f'https://arbitrum-mainnet.infura.io/v3/{project_id}',
            'optimism': f'https://optimism-mainnet.infura.io/v3/{project_id}',
            'base': f'https://base-mainnet.infura.io/v3/{project_id}',
        }

        if network not in urls:
            raise ValueError(f"Red no soportada: {network}. Usa: {list(urls.keys())}")

        return urls[network]

    def get_balance(self, address: Optional[str] = None) -> Dict[str, Any]:
        """
        Obtener balance de una dirección

        Args:
            address: Dirección a consultar (si None, usa la del backend)

        Returns:
            Dict con balance en Wei y ETH
        """
        print("=> address:", address)
        try:
            check_address = address or self.address
            check_address = Web3.to_checksum_address(check_address)

            balance_wei = self.w3.eth.get_balance(check_address)
            balance_eth = self.w3.from_wei(balance_wei, 'ether')

            return {
                'address': check_address,
                'balance_wei': str(balance_wei),
                'balance_eth': float(balance_eth),
                'network': self.network
            }
        except Exception as e:
            print(f"Error getting user: {str(e)}")
            return None

    def send_eth(
        self,
        to_address: str,
        amount_eth: float,
        gas_price_gwei: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Enviar ETH a una dirección

        Args:
            to_address: Dirección destino
            amount_eth: Cantidad en ETH
            gas_price_gwei: Precio del gas en Gwei (opcional, auto si None)

        Returns:
            Dict con información de la transacción
        """
        to_address = Web3.to_checksum_address(to_address)

        # Verificar balance
        balance = self.get_balance()
        if balance['balance_eth'] < amount_eth:
            raise ValueError(
                f"Balance insuficiente. "
                f"Tienes: {balance['balance_eth']} ETH, "
                f"Necesitas: {amount_eth} ETH"
            )

        # Obtener gas price
        if gas_price_gwei:
            gas_price = self.w3.to_wei(gas_price_gwei, 'gwei')
        else:
            gas_price = self.w3.eth.gas_price

        # Preparar transacción
        tx = {
            'from': self.address,
            'to': to_address,
            'value': self.w3.to_wei(amount_eth, 'ether'),
            'gas': 21000,  # Gas estándar para transferencia ETH
            'gasPrice': gas_price,
            'nonce': self.w3.eth.get_transaction_count(self.address),
            'chainId': self.w3.eth.chain_id
        }

        print(f"\n📤 Preparando transacción...")
        print(f"   De: {self.address}")
        print(f"   A: {to_address}")
        print(f"   Monto: {amount_eth} ETH")
        print(f"   Gas Price: {self.w3.from_wei(gas_price, 'gwei')} Gwei")

        # Firmar transacción
        signed_tx = self.account.sign_transaction(tx)

        print(f"✍️  Transacción firmada")

        # Enviar transacción
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        tx_hash_hex = tx_hash.hex()

        print(f"🚀 Transacción enviada: {tx_hash_hex}")
        print(f"   Esperando confirmación...")

        # Esperar confirmación
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash, timeout=300)

        status = 'success' if receipt['status'] == 1 else 'failed'

        print(f"✅ Transacción {status}")
        print(f"   Block: {receipt['blockNumber']}")
        print(f"   Gas usado: {receipt['gasUsed']}")

        return {
            'tx_hash': tx_hash_hex,
            'status': status,
            'block_number': receipt['blockNumber'],
            'gas_used': receipt['gasUsed'],
            'from': self.address,
            'to': to_address,
            'amount_eth': amount_eth,
            'explorer_url': self._get_explorer_url(tx_hash_hex)
        }

    def send_erc20(
        self,
        token_address: str,
        to_address: str,
        amount: float,
        decimals: int = 18,
        gas_limit: int = 100000
    ) -> Dict[str, Any]:
        """
        Enviar tokens ERC-20

        Args:
            token_address: Dirección del contrato del token
            to_address: Dirección destino
            amount: Cantidad de tokens
            decimals: Decimales del token (18 por defecto)
            gas_limit: Límite de gas

        Returns:
            Dict con información de la transacción
        """
        token_address = Web3.to_checksum_address(token_address)
        to_address = Web3.to_checksum_address(to_address)

        # ABI mínimo para ERC-20
        erc20_abi = [
            {
                'constant': False,
                'inputs': [
                    {'name': '_to', 'type': 'address'},
                    {'name': '_value', 'type': 'uint256'}
                ],
                'name': 'transfer',
                'outputs': [{'name': '', 'type': 'bool'}],
                'type': 'function'
            },
            {
                'constant': True,
                'inputs': [{'name': '_owner', 'type': 'address'}],
                'name': 'balanceOf',
                'outputs': [{'name': 'balance', 'type': 'uint256'}],
                'type': 'function'
            },
            {
                'constant': True,
                'inputs': [],
                'name': 'symbol',
                'outputs': [{'name': '', 'type': 'string'}],
                'type': 'function'
            }
        ]

        # Crear contrato
        contract = self.w3.eth.contract(
            address=token_address,
            abi=erc20_abi
        )

        # Obtener símbolo del token
        try:
            symbol = contract.functions.symbol().call()
        except Exception:
            symbol = 'TOKEN'

        # Verificar balance
        balance = contract.functions.balanceOf(self.address).call()
        balance_tokens = balance / (10 ** decimals)

        if balance_tokens < amount:
            raise ValueError(
                f"Balance insuficiente de {symbol}. "
                f"Tienes: {balance_tokens}, Necesitas: {amount}"
            )

        # Calcular cantidad en unidades mínimas
        amount_units = int(amount * (10 ** decimals))

        print(f"\n📤 Preparando transferencia de {symbol}...")
        print(f"   De: {self.address}")
        print(f"   A: {to_address}")
        print(f"   Monto: {amount} {symbol}")

        # Preparar transacción
        tx = contract.functions.transfer(
            to_address,
            amount_units
        ).build_transaction({
            'from': self.address,
            'gas': gas_limit,
            'gasPrice': self.w3.eth.gas_price,
            'nonce': self.w3.eth.get_transaction_count(self.address),
            'chainId': self.w3.eth.chain_id
        })

        # Firmar
        signed_tx = self.account.sign_transaction(tx)

        print(f"✍️  Transacción firmada")

        # Enviar
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        tx_hash_hex = tx_hash.hex()

        print(f"🚀 Transacción enviada: {tx_hash_hex}")
        print(f"   Esperando confirmación...")

        # Esperar confirmación
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash, timeout=300)

        status = 'success' if receipt['status'] == 1 else 'failed'

        print(f"✅ Transacción {status}")

        return {
            'tx_hash': tx_hash_hex,
            'status': status,
            'token': symbol,
            'token_address': token_address,
            'from': self.address,
            'to': to_address,
            'amount': amount,
            'block_number': receipt['blockNumber'],
            'gas_used': receipt['gasUsed'],
            'explorer_url': self._get_explorer_url(tx_hash_hex)
        }

    def _get_explorer_url(self, tx_hash: str) -> str:
        """Obtener URL del explorador de blockchain"""
        explorers = {
            'mainnet': f'https://etherscan.io/tx/{tx_hash}',
            'sepolia': f'https://sepolia.etherscan.io/tx/{tx_hash}',
            'polygon': f'https://polygonscan.com/tx/{tx_hash}',
            'polygon-amoy': f'https://amoy.polygonscan.com/tx/{tx_hash}',
            'arbitrum': f'https://arbiscan.io/tx/{tx_hash}',
            'optimism': f'https://optimistic.etherscan.io/tx/{tx_hash}',
            'base': f'https://basescan.org/tx/{tx_hash}',
        }

        return explorers.get(self.network, f'https://etherscan.io/tx/{tx_hash}')

    def estimate_gas_cost(self, amount_eth: float) -> Dict[str, Any]:
        """
        Estimar costo de gas para enviar ETH

        Args:
            amount_eth: Cantidad de ETH a enviar

        Returns:
            Dict con estimación de costos
        """
        gas_price = self.w3.eth.gas_price
        gas_limit = 21000  # Gas estándar para ETH

        total_cost_wei = gas_price * gas_limit
        total_cost_eth = self.w3.from_wei(total_cost_wei, 'ether')

        total_needed = amount_eth + float(total_cost_eth)

        return {
            'gas_price_gwei': float(self.w3.from_wei(gas_price, 'gwei')),
            'gas_limit': gas_limit,
            'gas_cost_eth': float(total_cost_eth),
            'amount_to_send': amount_eth,
            'total_needed_eth': total_needed,
            'network': self.network
        }

    def approve_token(
        self,
        token_address: str,
        spender_address: str,
        amount: Optional[float] = None,
        decimals: int = 18,
        gas_limit: int = 100000
    ) -> Dict[str, Any]:
        """
        Aprobar gasto de tokens ERC-20

        Args:
            token_address: Dirección del contrato del token
            spender_address: Dirección autorizada para gastar
            amount: Cantidad a aprobar (None = máximo uint256)
            decimals: Decimales del token (18 por defecto)
            gas_limit: Límite de gas

        Returns:
            Dict con información de la transacción
        """
        token_address = Web3.to_checksum_address(token_address)
        spender_address = Web3.to_checksum_address(spender_address)

        # ABI para approve
        erc20_abi = [
            {
                'constant': False,
                'inputs': [
                    {'name': '_spender', 'type': 'address'},
                    {'name': '_value', 'type': 'uint256'}
                ],
                'name': 'approve',
                'outputs': [{'name': '', 'type': 'bool'}],
                'type': 'function'
            },
            {
                'constant': True,
                'inputs': [],
                'name': 'symbol',
                'outputs': [{'name': '', 'type': 'string'}],
                'type': 'function'
            }
        ]

        contract = self.w3.eth.contract(address=token_address, abi=erc20_abi)

        # Obtener símbolo
        try:
            symbol = contract.functions.symbol().call()
        except Exception:
            symbol = 'TOKEN'

        # Calcular cantidad
        if amount is None:
            # Máximo uint256
            amount_units = 2**256 - 1
            amount_str = "MAX"
        else:
            amount_units = int(amount * (10 ** decimals))
            amount_str = str(amount)

        print(f"\n📤 Preparando aprobación de {symbol}...")
        print(f"   Token: {token_address}")
        print(f"   Spender: {spender_address}")
        print(f"   Monto: {amount_str} {symbol}")

        # Preparar transacción
        tx = contract.functions.approve(
            spender_address,
            amount_units
        ).build_transaction({
            'from': self.address,
            'gas': gas_limit,
            'gasPrice': self.w3.eth.gas_price,
            'nonce': self.w3.eth.get_transaction_count(self.address),
            'chainId': self.w3.eth.chain_id
        })

        # Firmar
        signed_tx = self.account.sign_transaction(tx)

        print(f"✍️  Transacción firmada")

        # Enviar
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        tx_hash_hex = tx_hash.hex()

        print(f"🚀 Transacción enviada: {tx_hash_hex}")
        print(f"   Esperando confirmación...")

        # Esperar confirmación
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash, timeout=300)

        status = 'success' if receipt['status'] == 1 else 'failed'

        print(f"✅ Transacción {status}")

        return {
            'tx_hash': tx_hash_hex,
            'status': status,
            'token': symbol,
            'token_address': token_address,
            'spender': spender_address,
            'amount': amount_str,
            'block_number': receipt['blockNumber'],
            'gas_used': receipt['gasUsed'],
            'explorer_url': self._get_explorer_url(tx_hash_hex)
        }

    def supply_to_aave(
        self,
        pool_address: str,
        asset_address: str,
        amount: float,
        on_behalf_of: Optional[str] = None,
        referral_code: int = 0,
        decimals: int = 18,
        gas_limit: int = 500000,
        auto_approve: bool = True
    ) -> Dict[str, Any]:
        """
        Suministrar tokens a Aave V3 Pool

        Args:
            pool_address: Dirección del contrato Pool de Aave V3
            asset_address: Dirección del token a suministrar
            amount: Cantidad de tokens a suministrar
            on_behalf_of: Dirección que recibirá los aTokens (None = wallet del backend)
            referral_code: Código de referido (0 por defecto)
            decimals: Decimales del token (18 por defecto)
            gas_limit: Límite de gas
            auto_approve: Si True, aprueba automáticamente el token antes de suministrar

        Returns:
            Dict con información de la transacción
        """
        pool_address = Web3.to_checksum_address(pool_address)
        asset_address = Web3.to_checksum_address(asset_address)
        on_behalf_of = Web3.to_checksum_address(on_behalf_of) if on_behalf_of else self.address

        # ABI para la función supply de Aave V3 Pool
        supply_abi = [
            {
                'inputs': [
                    {'internalType': 'address', 'name': 'asset', 'type': 'address'},
                    {'internalType': 'uint256', 'name': 'amount', 'type': 'uint256'},
                    {'internalType': 'address', 'name': 'onBehalfOf', 'type': 'address'},
                    {'internalType': 'uint16', 'name': 'referralCode', 'type': 'uint16'}
                ],
                'name': 'supply',
                'outputs': [],
                'stateMutability': 'nonpayable',
                'type': 'function'
            }
        ]

        # ABI para verificar balance y símbolo del token
        erc20_abi = [
            {
                'constant': True,
                'inputs': [{'name': '_owner', 'type': 'address'}],
                'name': 'balanceOf',
                'outputs': [{'name': 'balance', 'type': 'uint256'}],
                'type': 'function'
            },
            {
                'constant': True,
                'inputs': [],
                'name': 'symbol',
                'outputs': [{'name': '', 'type': 'string'}],
                'type': 'function'
            },
            {
                'constant': True,
                'inputs': [
                    {'name': '_owner', 'type': 'address'},
                    {'name': '_spender', 'type': 'address'}
                ],
                'name': 'allowance',
                'outputs': [{'name': '', 'type': 'uint256'}],
                'type': 'function'
            }
        ]

        # Crear contratos
        pool_contract = self.w3.eth.contract(address=pool_address, abi=supply_abi)
        token_contract = self.w3.eth.contract(address=asset_address, abi=erc20_abi)

        # Obtener símbolo del token
        try:
            symbol = token_contract.functions.symbol().call()
        except Exception:
            symbol = 'TOKEN'

        # Verificar balance
        balance = token_contract.functions.balanceOf(self.address).call()
        balance_tokens = balance / (10 ** decimals)
        amount_units = int(amount * (10 ** decimals))

        if balance_tokens < amount:
            raise ValueError(
                f"Balance insuficiente de {symbol}. "
                f"Tienes: {balance_tokens}, Necesitas: {amount}"
            )

        # Verificar y aprobar si es necesario
        if auto_approve:
            allowance = token_contract.functions.allowance(self.address, pool_address).call()
            if allowance < amount_units:
                print(f"\n⚠️  Aprobación insuficiente. Aprobando tokens...")
                approve_result = self.approve_token(
                    token_address=asset_address, # usdt0
                    spender_address=pool_address, # aave
                    amount=None,  # Aprobar máximo 10000
                    decimals=decimals # none
                )
                if approve_result['status'] != 'success':
                    raise ValueError(f"Error al aprobar tokens: {approve_result}")

        print(f"\n📤 Preparando supply a Aave V3...")
        print(f"   Pool: {pool_address}")
        print(f"   Asset: {asset_address} ({symbol})")
        print(f"   Cantidad: {amount} {symbol}")
        print(f"   On Behalf Of: {on_behalf_of}")
        print(f"   Referral Code: {referral_code}")

        # Preparar transacción
        tx = pool_contract.functions.supply(
            asset_address, # usdt0
            amount_units, # 0.1
            on_behalf_of, # my wallet
            referral_code # 0
        ).build_transaction({
            'from': self.address,
            'gas': gas_limit,
            'gasPrice': self.w3.eth.gas_price,
            'nonce': self.w3.eth.get_transaction_count(self.address),
            'chainId': self.w3.eth.chain_id
        })

        # Firmar
        signed_tx = self.account.sign_transaction(tx)

        print(f"✍️  Transacción firmada")

        # Enviar
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        tx_hash_hex = tx_hash.hex()

        print(f"🚀 Transacción enviada: {tx_hash_hex}")
        print(f"   Esperando confirmación...")

        # Esperar confirmación
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash, timeout=300)

        status = 'success' if receipt['status'] == 1 else 'failed'

        print(f"✅ Transacción {status}")
        print(f"   Block: {receipt['blockNumber']}")
        print(f"   Gas usado: {receipt['gasUsed']}")

        return {
            'tx_hash': tx_hash_hex,
            'status': status,
            'pool_address': pool_address,
            'asset': symbol,
            'asset_address': asset_address,
            'amount': amount,
            'on_behalf_of': on_behalf_of,
            'referral_code': referral_code,
            'block_number': receipt['blockNumber'],
            'gas_used': receipt['gasUsed'],
            'explorer_url': self._get_explorer_url(tx_hash_hex)
        }


# Función helper para crear wallet desde .env
def create_wallet_from_env() -> WalletManager:
    """Crear wallet usando variables de entorno"""
    private_key = os.getenv('BACKEND_PRIVATE_KEY')
    infura_project_id = os.getenv('INFURA_PROJECT_ID')
    network = os.getenv('NETWORK', 'sepolia')

    if not private_key:
        raise ValueError("BACKEND_PRIVATE_KEY no encontrada en .env")

    if not infura_project_id:
        raise ValueError("INFURA_PROJECT_ID no encontrada en .env")

    return WalletManager(
        private_key=private_key,
        infura_project_id=infura_project_id,
        network=network
    )
