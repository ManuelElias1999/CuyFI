// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IProtocolAdapter {
    function deposit(address asset, uint256 amount) external returns (uint256 shares);
    function withdraw(uint256 shares) external returns (uint256 amount);
    function totalValue() external view returns (uint256);
    function depositToken() external view returns (address);
    function receiptToken() external view returns (address);
    function stake(uint256 amount, bytes calldata data) external returns (uint256 receipts);
    function requestUnstake(uint256 receipts, bytes calldata data) external returns (bytes32 requestId);
    function finalizeUnstake(bytes32 requestId) external returns (uint256 amount);
    function harvest() external returns (address[] memory tokens, uint256[] memory amounts);
    function getPendingRewards() external view returns (uint256);
    function isWithdrawalClaimable(bytes32 requestId) external view returns (bool);
    function getProtocolName() external pure returns (string memory);
    function getDepositTokenForReceipts(uint256 receipts) external view returns (uint256);
}
