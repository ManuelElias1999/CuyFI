// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IBotVaultCore} from "./interfaces/IBotVaultCore.sol";

/**
 * @title VaultInit
 * @notice Initialization contract for Diamond pattern
 * @dev Used as _init parameter in diamondCut to initialize vault
 */
contract VaultInit {
    /**
     * @notice Initialize the vault
     * @param data Encoded initialization data for IBotVaultCore.initialize
     */
    function init(bytes calldata data) external {
        IBotVaultCore(address(this)).initialize(data);
    }
}
