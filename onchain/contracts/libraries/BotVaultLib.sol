// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ChainlinkOracleHelper} from "./ChainlinkOracleHelper.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

/**
 * @title BotVaultLib
 * @notice Simplified storage library for bot-controlled vault (based on MoreVaultsLib)
 * @dev Diamond storage pattern - single storage slot for all vault data
 */
library BotVaultLib {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // ============ Errors ============
    error UnauthorizedAccess();
    error ZeroAddress();
    error InvalidFee();
    error InvalidParameters();
    error UnsupportedAsset(address asset);
    error FunctionAlreadyExists(address oldFacetAddress, bytes4 selector);
    error FunctionDoesNotExist();
    error NoSelectorsInFacetToCut();
    error IncorrectFacetCutAction(uint8 action);
    error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

    // ============ Constants ============
    bytes32 constant BOT_VAULT_STORAGE_POSITION = keccak256("bot.vault.diamond.storage");
    uint96 constant FEE_BASIS_POINT = 10000; // 100%
    uint96 constant MAX_FEE = 2000; // 20% max fee

    // ============ Structs ============

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition;
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition;
    }

    struct ERC4626Storage {
        IERC20 _asset;
        uint8 _underlyingDecimals;
    }

    // Cross-chain deployment tracking (simplified - no oracles)
    struct CrossChainDeployment {
        uint32 dstEid; // destination chain ID
        address dstVault; // vault address on destination
        uint256 deployedAmount; // amount deployed
        uint256 lastUpdated; // timestamp of last update
    }

    struct BotVaultStorage {
        // ============ Diamond Pattern ============
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        address[] facetAddresses;
        bytes4[] selectors; // Array of all function selectors
        mapping(bytes4 => bool) supportedInterfaces;

        // ============ Access Control (Simplified) ============
        address owner;
        address agent; // Bot address that executes strategies

        // ============ ERC4626 Core ============
        address asset; // Primary asset (e.g., USDC)
        address feeRecipient;
        uint96 fee; // Performance fee in basis points

        // ============ Cross-Chain Tracking (Simplified) ============
        // deploymentId => CrossChainDeployment
        mapping(bytes32 => CrossChainDeployment) deployments;
        bytes32[] activeDeployments; // Array of active deployment IDs

        // Total deployed per chain (for quick lookup)
        mapping(uint32 => uint256) totalDeployedByChain;

        // ============ Integration Approvals ============
        mapping(address => bool) approvedProtocols; // Aave, Compound, etc
        mapping(address => bool) approvedDexs; // Uniswap, 1inch, etc
        mapping(address => bool) approvedOFTs; // LayerZero OFT adapters

        // ============ Composer Reference ============
        address composer; // MoreVaultsComposer address

        // ============ Oracles (Chainlink) ============
        mapping(address => ChainlinkOracleHelper.OracleInfo) assetOracles;

        // ============ Emergency ============
        bool paused;
    }

    // ============ Storage Access ============

    function botVaultStorage() internal pure returns (BotVaultStorage storage ds) {
        bytes32 position = BOT_VAULT_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // ============ Access Control Helpers ============

    function enforceIsOwner() internal view {
        if (msg.sender != botVaultStorage().owner) {
            revert UnauthorizedAccess();
        }
    }

    function enforceIsAgent() internal view {
        if (msg.sender != botVaultStorage().agent) {
            revert UnauthorizedAccess();
        }
    }

    function enforceIsOwnerOrAgent() internal view {
        BotVaultStorage storage ds = botVaultStorage();
        if (msg.sender != ds.owner && msg.sender != ds.agent) {
            revert UnauthorizedAccess();
        }
    }

    // ============ Fee Helpers ============

    function setFee(uint96 _fee) internal {
        if (_fee > MAX_FEE) revert InvalidFee();
        botVaultStorage().fee = _fee;
    }

    function setFeeRecipient(address _feeRecipient) internal {
        if (_feeRecipient == address(0)) revert ZeroAddress();
        botVaultStorage().feeRecipient = _feeRecipient;
    }

    // ============ Cross-Chain Tracking Helpers ============

    /**
     * @notice Record a new cross-chain deployment
     */
    function recordDeployment(
        uint32 _dstEid,
        address _dstVault,
        uint256 _amount
    ) internal returns (bytes32 deploymentId) {
        BotVaultStorage storage ds = botVaultStorage();

        // Generate unique deployment ID
        deploymentId = keccak256(abi.encodePacked(_dstEid, _dstVault, block.timestamp));

        ds.deployments[deploymentId] = CrossChainDeployment({
            dstEid: _dstEid,
            dstVault: _dstVault,
            deployedAmount: _amount,
            lastUpdated: block.timestamp
        });

        ds.activeDeployments.push(deploymentId);
        ds.totalDeployedByChain[_dstEid] += _amount;
    }

    /**
     * @notice Update deployment amount (when withdrawing or profits accrue)
     */
    function updateDeployment(bytes32 _deploymentId, uint256 _newAmount) internal {
        BotVaultStorage storage ds = botVaultStorage();
        CrossChainDeployment storage deployment = ds.deployments[_deploymentId];

        uint256 oldAmount = deployment.deployedAmount;
        uint32 dstEid = deployment.dstEid;

        // Update totals
        if (_newAmount > oldAmount) {
            ds.totalDeployedByChain[dstEid] += (_newAmount - oldAmount);
        } else {
            ds.totalDeployedByChain[dstEid] -= (oldAmount - _newAmount);
        }

        deployment.deployedAmount = _newAmount;
        deployment.lastUpdated = block.timestamp;
    }

    /**
     * @notice Remove a deployment (fully withdrawn)
     */
    function removeDeployment(bytes32 _deploymentId) internal {
        BotVaultStorage storage ds = botVaultStorage();
        CrossChainDeployment storage deployment = ds.deployments[_deploymentId];

        // Update total
        ds.totalDeployedByChain[deployment.dstEid] -= deployment.deployedAmount;

        // Remove from active deployments array
        for (uint256 i = 0; i < ds.activeDeployments.length; i++) {
            if (ds.activeDeployments[i] == _deploymentId) {
                ds.activeDeployments[i] = ds.activeDeployments[ds.activeDeployments.length - 1];
                ds.activeDeployments.pop();
                break;
            }
        }

        delete ds.deployments[_deploymentId];
    }

    /**
     * @notice Get total assets deployed cross-chain
     */
    function getTotalDeployed() internal view returns (uint256 total) {
        BotVaultStorage storage ds = botVaultStorage();
        for (uint256 i = 0; i < ds.activeDeployments.length; i++) {
            total += ds.deployments[ds.activeDeployments[i]].deployedAmount;
        }
    }

    // ============ Diamond Cut Functions ============

    /**
     * @notice Add/replace/remove facet functions
     * @param _diamondCut Array of facet cuts
     * @param _init Address to execute initialization
     * @param _calldata Initialization call data
     */
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;

            if (functionSelectors.length == 0) {
                revert NoSelectorsInFacetToCut();
            }

            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;

            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }

        emit IDiamondCut.DiamondCut(_diamondCut, _init, _calldata);

        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_facetAddress == address(0)) {
            revert InvalidParameters();
        }

        BotVaultStorage storage ds = botVaultStorage();
        uint16 selectorCount = uint16(ds.selectors.length);

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;

            if (oldFacetAddress != address(0)) {
                revert FunctionAlreadyExists(oldFacetAddress, selector);
            }

            ds.selectorToFacetAndPosition[selector] = FacetAddressAndPosition({
                facetAddress: _facetAddress,
                functionSelectorPosition: selectorCount
            });

            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_facetAddress == address(0)) {
            revert InvalidParameters();
        }

        BotVaultStorage storage ds = botVaultStorage();

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;

            if (oldFacetAddress == address(0)) {
                revert FunctionDoesNotExist();
            }

            // Can't replace immutable functions
            if (oldFacetAddress == address(this)) {
                revert InvalidParameters();
            }

            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_facetAddress != address(0)) {
            revert InvalidParameters();
        }

        BotVaultStorage storage ds = botVaultStorage();
        uint256 selectorCount = ds.selectors.length;

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndPosition memory oldFacetAddressAndPosition = ds.selectorToFacetAndPosition[selector];

            if (oldFacetAddressAndPosition.facetAddress == address(0)) {
                revert FunctionDoesNotExist();
            }

            // Can't remove immutable functions
            if (oldFacetAddressAndPosition.facetAddress == address(this)) {
                revert InvalidParameters();
            }

            // Replace selector with last selector, then delete last selector
            selectorCount--;

            if (oldFacetAddressAndPosition.functionSelectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndPosition.functionSelectorPosition] = lastSelector;
                ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition =
                    oldFacetAddressAndPosition.functionSelectorPosition;
            }

            ds.selectors.pop();
            delete ds.selectorToFacetAndPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }

        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }
}
