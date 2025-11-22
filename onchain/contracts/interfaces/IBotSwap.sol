// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IBotSwap
 * @notice Interface for DEX aggregator swaps
 */
interface IBotSwap {
    // ============ Structs ============

    struct SwapParams {
        address targetContract; // DEX aggregator address (Uniswap, 1inch, etc)
        address tokenIn;        // Token to sell
        address tokenOut;       // Token to buy
        uint256 amountIn;       // Exact amount to sell
        uint256 minAmountOut;   // Min amount to receive (slippage protection)
        bytes swapCallData;     // Complete calldata for the swap
    }

    // ============ Events ============

    event SwapExecuted(
        address indexed executor,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address targetContract
    );

    event BatchSwapExecuted(address indexed executor, uint256 swapCount);

    event DexApprovalUpdated(address indexed dex, bool approved);

    // ============ Errors ============

    error InvalidSwapTarget(address target);
    error SameToken(address token);
    error ZeroAmount();
    error ZeroMinAmount();
    error SlippageExceeded(uint256 received, uint256 minExpected);
    error SwapFailed(bytes reason);
    error UnexpectedAmountIn(uint256 expected, uint256 actual);
    error QuoteFailed(bytes reason);

    // ============ Functions ============

    /**
     * @notice Execute a single swap
     */
    function executeSwap(SwapParams calldata params) external returns (uint256 amountOut);

    /**
     * @notice Execute multiple swaps atomically
     */
    function executeBatchSwap(SwapParams[] calldata swaps) external returns (uint256[] memory amountsOut);

    /**
     * @notice Get quote from DEX quoter
     */
    function getQuote(address quoter, bytes calldata quoteCallData) external view returns (bytes memory quoteResult);

    /**
     * @notice Approve/revoke DEX
     */
    function approveDex(address dex, bool approved) external;

    /**
     * @notice Check if DEX is approved
     */
    function isDexApproved(address dex) external view returns (bool);
}
