// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStandardizedYield {
    function deposit(address receiver, address tokenIn, uint256 amountTokenToDeposit, uint256 minSharesOut) external returns (uint256 amountSharesOut);
    function redeem(address receiver, uint256 amountSharesToRedeem, address tokenOut, uint256 minTokenOut, bool burnFromInternalBalance) external returns (uint256 amountTokenOut);
}
