// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {BotVaultCoreFacet} from "../contracts/facets/BotVaultCoreFacet.sol";
import {BotVaultLib} from "../contracts/libraries/BotVaultLib.sol";

/**
 * @notice Unit test for BotVault constants and functions
 */
contract BotVaultCoreTest is Test {
    function testLibraryConstants() public {
        // Test that MAX_FEE is 2000 basis points (20%)
        assertEq(BotVaultLib.MAX_FEE, 2000);

        // Test that FEE_BASIS_POINT is 10000 (100%)
        assertEq(BotVaultLib.FEE_BASIS_POINT, 10000);
    }

    function testFeeCalculation() public {
        // 5% fee = 500 basis points
        uint96 fee = 500;
        uint256 amount = 1000e6;

        uint256 feeAmount = (amount * fee) / BotVaultLib.FEE_BASIS_POINT;
        assertEq(feeAmount, 50e6); // 5% of 1000 = 50
    }

    function testMaxFeeCalculation() public {
        // 20% max fee = 2000 basis points
        uint256 amount = 1000e6;

        uint256 maxFeeAmount = (amount * BotVaultLib.MAX_FEE) / BotVaultLib.FEE_BASIS_POINT;
        assertEq(maxFeeAmount, 200e6); // 20% of 1000 = 200
    }

    function testStoragePosition() public {
        // Test that storage position is deterministic
        bytes32 storagePos = keccak256("bot.vault.diamond.storage");
        assertEq(BotVaultLib.BOT_VAULT_STORAGE_POSITION, storagePos);
    }
}
