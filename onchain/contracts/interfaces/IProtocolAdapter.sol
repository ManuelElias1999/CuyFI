// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IProtocolAdapter {
    function deposit(address asset, uint256 amount) external returns (uint256 shares);
    function withdraw(uint256 shares) external returns (uint256 amount);
    function totalValue() external view returns (uint256);
}
