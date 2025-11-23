// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {BotVaultLib} from "../libraries/BotVaultLib.sol";

// ULN Config struct
struct UlnConfig {
    uint64 confirmations;
    uint8 requiredDVNCount;
    uint8 optionalDVNCount;
    uint8 optionalDVNThreshold;
    address[] requiredDVNs;
    address[] optionalDVNs;
}

/**
 * @title LayerZeroConfigFacet
 * @notice Diamond facet for configuring LayerZero OApp settings
 * @dev Allows Diamond to configure itself with LayerZero endpoint
 */
contract LayerZeroConfigFacet {
    event LzDelegateSet(address indexed delegate);
    event LzSendLibrarySet(uint32 indexed eid, address sendLibrary);
    event LzReceiveLibrarySet(uint32 indexed eid, address receiveLibrary);
    event LzConfigSet(uint32 indexed eid, uint32 configType);

    error Unauthorized();

    uint32 constant CONFIG_TYPE_ULN = 2;

    /**
     * @notice Set LayerZero delegate
     * @param _delegate Delegate address
     */
    function setLzDelegate(address _delegate) external {
        BotVaultLib.enforceIsOwner();
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        ILayerZeroEndpointV2(ds.lzEndpoint).setDelegate(_delegate);
        emit LzDelegateSet(_delegate);
    }

    /**
     * @notice Set send library for destination chain
     * @param _eid Destination endpoint ID
     * @param _sendLibrary Send library address
     */
    function setLzSendLibrary(uint32 _eid, address _sendLibrary) external {
        BotVaultLib.enforceIsOwner();
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        ILayerZeroEndpointV2(ds.lzEndpoint).setSendLibrary(
            address(this), // oapp address
            _eid,
            _sendLibrary
        );
        emit LzSendLibrarySet(_eid, _sendLibrary);
    }

    /**
     * @notice Set receive library for destination chain
     * @param _eid Destination endpoint ID
     * @param _receiveLibrary Receive library address
     * @param _gracePeriod Grace period in seconds
     */
    function setLzReceiveLibrary(uint32 _eid, address _receiveLibrary, uint256 _gracePeriod) external {
        BotVaultLib.enforceIsOwner();
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        ILayerZeroEndpointV2(ds.lzEndpoint).setReceiveLibrary(
            address(this), // oapp address
            _eid,
            _receiveLibrary,
            _gracePeriod
        );
        emit LzReceiveLibrarySet(_eid, _receiveLibrary);
    }

    /**
     * @notice Configure ULN with DVNs
     * @param _eid Destination endpoint ID
     * @param _sendLibrary Send library address
     * @param _confirmations Number of confirmations
     * @param _requiredDVNs Required DVN addresses
     */
    function setLzUlnConfig(
        uint32 _eid,
        address _sendLibrary,
        uint64 _confirmations,
        address[] calldata _requiredDVNs
    ) external {
        BotVaultLib.enforceIsOwner();
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        // Build ULN config
        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: _confirmations,
            requiredDVNCount: uint8(_requiredDVNs.length),
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: _requiredDVNs,
            optionalDVNs: new address[](0)
        });

        // Build SetConfigParam array
        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = SetConfigParam({
            eid: _eid,
            configType: CONFIG_TYPE_ULN,
            config: abi.encode(ulnConfig)
        });

        // Call setConfig
        ILayerZeroEndpointV2(ds.lzEndpoint).setConfig(
            address(this), // oapp
            _sendLibrary,
            params
        );

        emit LzConfigSet(_eid, CONFIG_TYPE_ULN);
    }
}
