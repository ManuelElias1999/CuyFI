// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {ApiDexAdapter} from "../contracts/adapters/ApiDexAdapter.sol";
import {IDexAdapter} from "../contracts/interfaces/IDexAdapter.sol";

/**
 * @title ApiDexAdapterTest
 * @notice Unit tests for ApiDexAdapter
 */
contract ApiDexAdapterTest is Test {
    ApiDexAdapter adapter;

    address constant WFLOW = 0xd3bF53DAC106A0290B0483EcBC89d40FcC961f3e;
    address constant STG_USDC = 0xF1815bd50389c46847f0Bda824eC8da914045D14;

    function setUp() public {
        adapter = new ApiDexAdapter();
    }

    function test_adapterName() public view {
        assertEq(adapter.adapterName(), "API DEX Adapter");
    }

    function test_isChainSupported_AlwaysTrue() public view {
        assertTrue(adapter.isChainSupported(747)); // Flow
        assertTrue(adapter.isChainSupported(1)); // Ethereum
        assertTrue(adapter.isChainSupported(42161)); // Arbitrum
    }

    function test_getSupportedChains_ReturnsEmpty() public view {
        uint256[] memory chains = adapter.getSupportedChains();
        assertEq(chains.length, 0);
    }

    function test_getRouterAddress_Reverts() public {
        vm.expectRevert(IDexAdapter.RouterNotSet.selector);
        adapter.getRouterAddress();
    }

    function test_getQuoterAddress_Reverts() public {
        vm.expectRevert(IDexAdapter.QuoterNotAvailable.selector);
        adapter.getQuoterAddress();
    }

    function test_getQuote_Reverts() public {
        vm.expectRevert(IDexAdapter.QuoterNotAvailable.selector);
        adapter.getQuote(WFLOW, STG_USDC, 1 ether);
    }

    function test_estimateGas_ReturnsConservative() public view {
        uint256 gasEstimate = adapter.estimateGas(WFLOW, STG_USDC, 1 ether);
        assertEq(gasEstimate, 300000);
    }

    function test_buildSwapCalldata_Reverts() public {
        vm.expectRevert("ApiDexAdapter: Use buildSwapCalldataWithParams with API data");
        adapter.buildSwapCalldata(WFLOW, STG_USDC, 1 ether, 0.9 ether, address(this));
    }

    function test_buildSwapCalldataWithParams_ValidatesAndReturns() public view {
        bytes memory apiCalldata = hex"1234567890abcdef";

        bytes memory result = adapter.buildSwapCalldataWithParams(
            WFLOW,
            STG_USDC,
            1 ether,
            0.9 ether,
            address(this),
            apiCalldata
        );

        assertEq(result, apiCalldata, "Should return API calldata unchanged");
    }

    function test_buildSwapCalldataWithParams_RevertsOnZeroTokenIn() public {
        bytes memory apiCalldata = hex"1234567890abcdef";

        vm.expectRevert(IDexAdapter.InvalidToken.selector);
        adapter.buildSwapCalldataWithParams(
            address(0),
            STG_USDC,
            1 ether,
            0.9 ether,
            address(this),
            apiCalldata
        );
    }

    function test_buildSwapCalldataWithParams_RevertsOnZeroTokenOut() public {
        bytes memory apiCalldata = hex"1234567890abcdef";

        vm.expectRevert(IDexAdapter.InvalidToken.selector);
        adapter.buildSwapCalldataWithParams(
            WFLOW,
            address(0),
            1 ether,
            0.9 ether,
            address(this),
            apiCalldata
        );
    }

    function test_buildSwapCalldataWithParams_RevertsOnSameTokens() public {
        bytes memory apiCalldata = hex"1234567890abcdef";

        vm.expectRevert(IDexAdapter.InvalidToken.selector);
        adapter.buildSwapCalldataWithParams(
            WFLOW,
            WFLOW,
            1 ether,
            0.9 ether,
            address(this),
            apiCalldata
        );
    }

    function test_buildSwapCalldataWithParams_RevertsOnZeroAmountIn() public {
        bytes memory apiCalldata = hex"1234567890abcdef";

        vm.expectRevert(IDexAdapter.InvalidAmount.selector);
        adapter.buildSwapCalldataWithParams(
            WFLOW,
            STG_USDC,
            0,
            0.9 ether,
            address(this),
            apiCalldata
        );
    }

    function test_buildSwapCalldataWithParams_RevertsOnZeroMinAmountOut() public {
        bytes memory apiCalldata = hex"1234567890abcdef";

        vm.expectRevert(IDexAdapter.InvalidAmount.selector);
        adapter.buildSwapCalldataWithParams(
            WFLOW,
            STG_USDC,
            1 ether,
            0,
            address(this),
            apiCalldata
        );
    }

    function test_buildSwapCalldataWithParams_RevertsOnZeroReceiver() public {
        bytes memory apiCalldata = hex"1234567890abcdef";

        vm.expectRevert(IDexAdapter.InvalidReceiver.selector);
        adapter.buildSwapCalldataWithParams(
            WFLOW,
            STG_USDC,
            1 ether,
            0.9 ether,
            address(0),
            apiCalldata
        );
    }

    function test_buildSwapCalldataWithParams_RevertsOnEmptyCalldata() public {
        bytes memory apiCalldata = "";

        vm.expectRevert(IDexAdapter.InvalidSwapPath.selector);
        adapter.buildSwapCalldataWithParams(
            WFLOW,
            STG_USDC,
            1 ether,
            0.9 ether,
            address(this),
            apiCalldata
        );
    }

    function test_validateSwapParams_ValidCase() public view {
        bool valid = adapter.validateSwapParams(WFLOW, STG_USDC, 1 ether, 0.9 ether);
        assertTrue(valid);
    }

    function test_validateSwapParams_InvalidZeroTokenIn() public view {
        bool valid = adapter.validateSwapParams(address(0), STG_USDC, 1 ether, 0.9 ether);
        assertFalse(valid);
    }

    function test_validateSwapParams_InvalidZeroTokenOut() public view {
        bool valid = adapter.validateSwapParams(WFLOW, address(0), 1 ether, 0.9 ether);
        assertFalse(valid);
    }

    function test_validateSwapParams_InvalidSameTokens() public view {
        bool valid = adapter.validateSwapParams(WFLOW, WFLOW, 1 ether, 0.9 ether);
        assertFalse(valid);
    }

    function test_validateSwapParams_InvalidZeroAmountIn() public view {
        bool valid = adapter.validateSwapParams(WFLOW, STG_USDC, 0, 0.9 ether);
        assertFalse(valid);
    }

    function test_validateSwapParams_InvalidZeroMinAmountOut() public view {
        bool valid = adapter.validateSwapParams(WFLOW, STG_USDC, 1 ether, 0);
        assertFalse(valid);
    }

    function test_decodeSwapResult_ReturnsZero() public view {
        bytes memory result = hex"1234567890";
        uint256 amountOut = adapter.decodeSwapResult(result);
        assertEq(amountOut, 0);
    }
}
