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
  // 1. PROVIDER CONFIGURATION (MOCK WALLET IN BACKEND)
  // ---------------------------------------------------------
  const privateKey = process.env.PRIVATE_KEY as `0x${string}`;
  const account = privateKeyToAccount(privateKey);

  // Create a Viem client that will act as our "MetaMask" on the server
  const client = createWalletClient({
    account,
    chain: mainnet,
    transport: http() // Use public RPC or your own Infura/Alchemy endpoint
  });

  // Adapter so the SDK thinks it's in a browser (EIP-1193)
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

  console.log(`🤖 Starting Nexus SDK with wallet: ${account.address}`);

  // ---------------------------------------------------------
  // 2. SDK INITIALIZATION
  // ---------------------------------------------------------
  const sdk = new NexusSDK({
    network: 'mainnet' as NexusNetwork
  });

  // Critical Step! Connect the provider to the SDK
  await sdk.initialize(backendProvider as any);

  // ---------------------------------------------------------
  // 3. DATA FOR EXECUTION ON ARBITRUM (AAVE V3 + USDT)
  // ---------------------------------------------------------
  const AAVE_POOL_ARB = "0x794a61358D6845594F94dc1DB02A252b5b4814aD";
  const USDT_ARB = "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9";
  
  // Amount: 10 USDT (USDT has 6 decimals)
  const amountToBridge = parseUnits('10', 6);

  // ABI for the 'supply' function of the Aave contract
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
  // 4. EXECUTION (BRIDGE AND EXECUTE)
  // ---------------------------------------------------------
  try {
    console.log("🚀 Sending Bridge & Execute intent...");

    const tx = await sdk.bridgeAndExecute({
      // Source
      token: 'USDT',         // Token to take from Ethereum Mainnet
      amount: amountToBridge.toString(), // Must be bigint or string
      sourceChains: [1],     // Chain IDs where you have funds (1 = Mainnet)
      
      // Destination
      toChainId: 42161,      // Arbitrum One
      
      // Execution (Payload)
      execute: {
        contractAddress: AAVE_POOL_ARB,   // Destination contract
        contractAbi: supplyAbi,           // Contract ABI
        functionName: 'supply',           // Function name
        buildFunctionParams: (_token: string, _amount: string, _chainId: number, userAddress: `0x${string}`) => {
          return {
            functionParams: [USDT_ARB, amountToBridge, userAddress, 0]
          };
        },
        value: '0',          // ETH value to send (0 for ERC20)
        
        // Optional: Automatic approval at destination if needed
        tokenApproval: {
            token: 'USDT',
            amount: amountToBridge.toString()
        }
      }
    });

    console.log(`✅ Transaction sent successfully!`);
    console.log(`Bridge hash: ${tx.bridgeTransactionHash}`);
    console.log(`Execution hash: ${tx.executeTransactionHash}`);
    
  } catch (error) {
    console.error("❌ Error executing the Bridge:", error);
  }
}

main();