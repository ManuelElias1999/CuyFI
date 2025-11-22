// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPYieldToken {
    function SY() external view returns (address);
    function redeemPY(address receiver) external returns (uint256 amountSyOut);
}
