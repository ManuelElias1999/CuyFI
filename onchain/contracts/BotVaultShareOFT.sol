// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BotVaultShareOFT
 * @notice OFT Adapter for BotVault shares (bvUSDT)
 * @dev Wraps ERC20 vault shares to enable cross-chain transfers via LayerZero
 *
 * Architecture:
 * - Hub (Arbitrum): OFTAdapter locks shares, mints on destination
 * - Spokes (Polygon, etc): OFT represents locked shares from hub
 */
contract BotVaultShareOFT is OFTAdapter {
    /**
     * @notice Initialize the Share OFT Adapter
     * @param _token Address of the vault share token (BotVaultDiamond)
     * @param _lzEndpoint LayerZero endpoint address
     * @param _owner Owner address for access control
     */
    constructor(
        address _token,
        address _lzEndpoint,
        address _owner
    ) OFTAdapter(_token, _lzEndpoint, _owner) Ownable(_owner) {}
}
