// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {BotVaultLib} from "../libraries/BotVaultLib.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";

/**
 * @title DiamondLoupeFacet
 * @notice Facet for Diamond inspection (EIP-2535)
 * @dev Provides read-only functions to inspect the Diamond
 */
contract DiamondLoupeFacet is IDiamondLoupe {
    /**
     * @inheritdoc IDiamondLoupe
     */
    function facets() external view override returns (Facet[] memory facets_) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets;) {
            address facetAddress_ = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IDiamondLoupe
     */
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        facetFunctionSelectors_ = ds.facetFunctionSelectors[_facet].functionSelectors;
    }

    /**
     * @inheritdoc IDiamondLoupe
     */
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    /**
     * @inheritdoc IDiamondLoupe
     */
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }

    /**
     * @notice Check if interface is supported (ERC-165)
     * @param _interfaceId The interface identifier
     * @return True if supported
     */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}
