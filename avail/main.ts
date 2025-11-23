// Import polyfill first to set up WebSocket
import './polynfill.js';

import { createWalletClient, http, parseUnits } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { mainnet } from 'viem/chains';
import dotenv from 'dotenv';

dotenv.config();

// Dynamic import to work around tsx module resolution issue
const NexusCore = await import('@avail-project/nexus-core');
const NexusSDK = (NexusCore as any).NexusSDK || NexusCore.default?.NexusSDK || (NexusCore as any).default;
type NexusNetwork = 'mainnet' | 'testnet';

async function main() {
  // ---------------------------------------------------------
  // 1. CONFIGURACIÓN DEL PROVEEDOR (MOCK DE WALLET EN BACKEND)
  // ---------------------------------------------------------
  const privateKey = process.env.PRIVATE_KEY as `0x${string}`;
  const account = privateKeyToAccount(privateKey);

  // Creamos un cliente de Viem que actuará como nuestra "MetaMask" en el servidor
  const client = createWalletClient({
    account,
    chain: mainnet,
    transport: http() // Usa RPC público o tu propio endpoint de Infura/Alchemy
  });

  // Adaptador para que el SDK crea que está en un navegador (EIP-1193)
  const backendProvider = {
    request: async (args: any) => {
      if (args.method === 'eth_requestAccounts' || args.method === 'eth_accounts') {
        return [account.address];
      }
      if (args.method === 'wallet_switchEthereumChain') {
        return null; // Mock success
      }
      return await client.request(args);
    },
    on: () => {},
    removeListener: () => {},
    isMetaMask: false,
    selectedAddress: account.address,
    chainId: `0x${mainnet.id.toString(16)}`
  };

  console.log(`🤖 Iniciando Nexus SDK con wallet: ${account.address}`);

  // ---------------------------------------------------------
  // 2. INICIALIZACIÓN DEL SDK
  // ---------------------------------------------------------
  const sdk = new NexusSDK({
    network: 'mainnet' as NexusNetwork
  });

  // ¡Paso Crítico! Conectar el proveedor al SDK
  await sdk.initialize(backendProvider as any);

  // ---------------------------------------------------------
  // 3. DATOS PARA EJECUCIÓN EN ARBITRUM (AAVE V3 + USDT)
  // ---------------------------------------------------------
  const AAVE_POOL_ARB = "0x794a61358D6845594F94dc1DB02A252b5b4814aD";
  const USDT_ARB = "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9";
  
  // Cantidad: 10 USDT (USDT tiene 6 decimales)
  const amountToBridge = parseUnits('10', 6);

  // ABI para la función 'supply' del contrato de Aave
  const supplyAbi = [{
    inputs: [
      { name: 'asset', type: 'address' },
      { name: 'amount', type: 'uint256' },
      { name: 'onBehalfOf', type: 'address' },
      { name: 'referralCode', type: 'uint16' }
    ],
    name: 'supply',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  }] as const;

  // ---------------------------------------------------------
  // 4. EJECUCIÓN (BRIDGE AND EXECUTE)
  // ---------------------------------------------------------
  try {
    console.log("🚀 Enviando intención Bridge & Execute...");

    const tx = await sdk.bridgeAndExecute({
      // Origen
      token: 'USDT',         // Token a tomar de Ethereum Mainnet
      amount: amountToBridge.toString(), // Debe ser bigint o string
      sourceChains: [1],     // IDs de cadenas donde tienes fondos (1 = Mainnet)
      
      // Destino
      toChainId: 42161,      // Arbitrum One
      
      // Ejecución (Payload)
      execute: {
        contractAddress: AAVE_POOL_ARB,   // Contrato destino
        contractAbi: supplyAbi,           // ABI del contrato
        functionName: 'supply',           // Nombre de la función
        buildFunctionParams: (_token: string, _amount: string, _chainId: number, userAddress: `0x${string}`) => {
          return {
            functionParams: [USDT_ARB, amountToBridge, userAddress, 0]
          };
        },
        value: '0',          // Valor en ETH a enviar (0 para ERC20)
        
        // Opcional: Aprobación automática en destino si fuera necesaria
        tokenApproval: {
            token: 'USDT',
            amount: amountToBridge.toString()
        }
      }
    });

    console.log(`✅ Transacción enviada con éxito!`);
    console.log(`Hash de bridge: ${tx.bridgeTransactionHash}`);
    console.log(`Hash de ejecución: ${tx.executeTransactionHash}`);
    
  } catch (error) {
    console.error("❌ Error ejecutando el Bridge:", error);
  }
}

main();