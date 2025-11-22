// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {BotVaultLib} from "../libraries/BotVaultLib.sol";
import {IBotSwap} from "../interfaces/IBotSwap.sol";

/**
 * @title BotSwapFacet
 * @notice Generic DEX aggregator for swaps (simplified from DexAggregatorFacet)
 * @dev Supports any DEX: Uniswap, 1inch, Paraswap, 0x, etc.
 */
contract BotSwapFacet is IBotSwap, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Modifiers ============

    modifier onlyAgent() {
        BotVaultLib.enforceIsAgent();
        _;
    }

    modifier onlyOwnerOrAgent() {
        BotVaultLib.enforceIsOwnerOrAgent();
        _;
    }

    // ============ Swap Execution ============

    /**
     * @notice Execute a token swap through any approved DEX
     * @dev Agent-only, validates inputs and checks balance changes
     * @param params Swap parameters (tokenIn, tokenOut, amount, dex calldata)
     * @return amountOut Actual amount received
     */
    function executeSwap(SwapParams calldata params)
        external
        override
        onlyAgent
        nonReentrant
        returns (uint256 amountOut)
    {
        _validateSwapParams(params);

        // Record balances before
        uint256 tokenInBalanceBefore = IERC20(params.tokenIn).balanceOf(address(this));
        uint256 tokenOutBalanceBefore = IERC20(params.tokenOut).balanceOf(address(this));

        // Approve target DEX
        IERC20(params.tokenIn).forceApprove(params.targetContract, params.amountIn);

        // Execute swap
        (bool success, bytes memory result) = params.targetContract.call(params.swapCallData);

        // Reset approval
        IERC20(params.tokenIn).forceApprove(params.targetContract, 0);

        if (!success) {
            revert SwapFailed(result);
        }

        // Verify balance changes
        uint256 tokenInBalanceAfter = IERC20(params.tokenIn).balanceOf(address(this));
        uint256 tokenOutBalanceAfter = IERC20(params.tokenOut).balanceOf(address(this));

        uint256 actualAmountIn = tokenInBalanceBefore - tokenInBalanceAfter;
        if (actualAmountIn != params.amountIn) {
            revert UnexpectedAmountIn(params.amountIn, actualAmountIn);
        }

        amountOut = tokenOutBalanceAfter - tokenOutBalanceBefore;
        if (amountOut < params.minAmountOut) {
            revert SlippageExceeded(amountOut, params.minAmountOut);
        }

        emit SwapExecuted(msg.sender, params.tokenIn, params.tokenOut, actualAmountIn, amountOut, params.targetContract);

        return amountOut;
    }

    /**
     * @notice Execute multiple swaps atomically
     * @dev Useful for rebalancing - e.g., USDT->USDC->DAI in one tx
     * @param swaps Array of swap parameters
     * @return amountsOut Array of amounts received for each swap
     */
    function executeBatchSwap(SwapParams[] calldata swaps)
        external
        override
        onlyAgent
        nonReentrant
        returns (uint256[] memory amountsOut)
    {
        amountsOut = new uint256[](swaps.length);

        for (uint256 i = 0; i < swaps.length; i++) {
            amountsOut[i] = _executeSwapInternal(swaps[i]);
        }

        emit BatchSwapExecuted(msg.sender, swaps.length);

        return amountsOut;
    }

    /**
     * @notice Get a quote from any DEX quoter
     * @dev Returns raw bytes - caller must decode
     * @param quoter Address of the quoter contract
     * @param quoteCallData Calldata for the quote function
     * @return quoteResult Raw bytes from quoter
     */
    function getQuote(address quoter, bytes calldata quoteCallData)
        external
        view
        override
        returns (bytes memory quoteResult)
    {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        if (!ds.approvedDexs[quoter]) revert InvalidSwapTarget(quoter);

        (bool success, bytes memory result) = quoter.staticcall(quoteCallData);

        if (!success) {
            revert QuoteFailed(result);
        }

        return result;
    }

    // ============ Configuration ============

    /**
     * @notice Approve/revoke a DEX aggregator
     * @param dex Address of the DEX contract
     * @param approved Approval status
     */
    function approveDex(address dex, bool approved) external override onlyOwnerOrAgent {
        BotVaultLib.botVaultStorage().approvedDexs[dex] = approved;
        emit DexApprovalUpdated(dex, approved);
    }

    /**
     * @notice Check if a DEX is approved
     */
    function isDexApproved(address dex) external view override returns (bool) {
        return BotVaultLib.botVaultStorage().approvedDexs[dex];
    }

    // ============ Internal Functions ============

    function _executeSwapInternal(SwapParams calldata params) private returns (uint256 amountOut) {
        _validateSwapParams(params);

        uint256 tokenInBalanceBefore = IERC20(params.tokenIn).balanceOf(address(this));
        uint256 tokenOutBalanceBefore = IERC20(params.tokenOut).balanceOf(address(this));

        IERC20(params.tokenIn).forceApprove(params.targetContract, params.amountIn);

        (bool success, bytes memory result) = params.targetContract.call(params.swapCallData);

        IERC20(params.tokenIn).forceApprove(params.targetContract, 0);

        if (!success) {
            revert SwapFailed(result);
        }

        uint256 tokenInBalanceAfter = IERC20(params.tokenIn).balanceOf(address(this));
        uint256 tokenOutBalanceAfter = IERC20(params.tokenOut).balanceOf(address(this));

        uint256 actualAmountIn = tokenInBalanceBefore - tokenInBalanceAfter;
        if (actualAmountIn != params.amountIn) {
            revert UnexpectedAmountIn(params.amountIn, actualAmountIn);
        }

        amountOut = tokenOutBalanceAfter - tokenOutBalanceBefore;
        if (amountOut < params.minAmountOut) {
            revert SlippageExceeded(amountOut, params.minAmountOut);
        }

        emit SwapExecuted(msg.sender, params.tokenIn, params.tokenOut, actualAmountIn, amountOut, params.targetContract);

        return amountOut;
    }

    function _validateSwapParams(SwapParams calldata params) private view {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        if (!ds.approvedDexs[params.targetContract]) {
            revert InvalidSwapTarget(params.targetContract);
        }

        if (params.tokenIn == params.tokenOut) {
            revert SameToken(params.tokenIn);
        }

        if (params.amountIn == 0) {
            revert ZeroAmount();
        }

        if (params.minAmountOut == 0) {
            revert ZeroMinAmount();
        }
    }
}
