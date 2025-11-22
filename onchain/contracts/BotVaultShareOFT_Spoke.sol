// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BotVaultShareOFT_Spoke
 * @notice OFT for BotVault shares on spoke chains (Polygon, Optimism)
 * @dev This is a standalone OFT (not adapter) that represents shares locked on hub
 *
 * Architecture:
 * - Hub (Arbitrum): OFTAdapter locks real shares, sends to spokes
 * - Spokes (Polygon, Optimism): OFT mints/burns virtual shares
 *
 * When user deposits USDT from Polygon:
 * 1. USDT sent to Arbitrum hub
 * 2. Hub mints real shares in vault
 * 3. Hub sends shares back via OFTAdapter -> this spoke OFT
 * 4. This OFT mints virtual shares to user on Polygon
 */
contract BotVaultShareOFT_Spoke is OFT {
    /**
     * @notice Initialize the Spoke Share OFT
     * @param _lzEndpoint LayerZero endpoint address
     * @param _owner Owner address for access control
     */
    constructor(
        address _lzEndpoint,
        address _owner
    ) OFT("BotVault USDT Shares", "bvUSDT", _lzEndpoint, _owner) Ownable(_owner) {}
}
