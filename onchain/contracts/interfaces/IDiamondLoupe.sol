// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IDiamondLoupe
 * @notice Interface for Diamond inspection (EIP-2535)
 * @dev Allows querying which facets and functions are available
 */
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Gets all facets and their selectors
     * @return facets_ Array of Facet structs
     */
    function facets() external view returns (Facet[] memory facets_);

    /**
     * @notice Gets all function selectors supported by a specific facet
     * @param _facet The facet address
     * @return facetFunctionSelectors_ The selectors
     */
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /**
     * @notice Gets all facet addresses used by the diamond
     * @return facetAddresses_ Array of facet addresses
     */
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /**
     * @notice Gets the facet that supports the given selector
     * @param _functionSelector The function selector
     * @return facetAddress_ The facet address
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}
