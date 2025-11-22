// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title BotVaultDiamond
 * @notice EIP-2535 Diamond implementation for BotVault
 * @dev https://eips.ethereum.org/EIPS/eip-2535
 */
import {BotVaultLib} from "./libraries/BotVaultLib.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

contract BotVaultDiamond {
    error FunctionDoesNotExist();

    constructor(address _owner) payable {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        ds.owner = _owner;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        BotVaultLib.BotVaultStorage storage ds;
        bytes32 position = BotVaultLib.BOT_VAULT_STORAGE_POSITION;

        // Get diamond storage
        assembly {
            ds.slot := position
        }

        // Get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        if (facet == address(0)) {
            revert FunctionDoesNotExist();
        }

        // Execute external function from facet using delegatecall and return any value
        assembly {
            // Copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // Execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // Get any return value
            returndatacopy(0, 0, returndatasize())
            // Return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}

    /**
     * @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external {
        BotVaultLib.enforceIsOwner();
        BotVaultLib.diamondCut(_diamondCut, _init, _calldata);
    }
}
