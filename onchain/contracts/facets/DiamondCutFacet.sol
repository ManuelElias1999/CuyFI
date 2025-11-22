// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {BotVaultLib} from "../libraries/BotVaultLib.sol";

/**
 * @title DiamondCutFacet
 * @notice Facet for Diamond upgrades (EIP-2535)
 * @dev Allows adding/replacing/removing facets
 */
contract DiamondCutFacet is IDiamondCut {
    /**
     * @inheritdoc IDiamondCut
     */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        BotVaultLib.enforceIsOwner();
        BotVaultLib.diamondCut(_diamondCut, _init, _calldata);
    }
}
