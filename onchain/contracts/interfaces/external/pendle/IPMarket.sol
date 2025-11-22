// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPMarket {
    function readTokens() external view returns (address SY, address PT, address YT);
}
