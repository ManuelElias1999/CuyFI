// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ILayerZeroEndpointV2, MessagingParams, MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {BotVaultLib} from "../libraries/BotVaultLib.sol";

/**
 * @title RatioBroadcastFacet
 * @notice Diamond facet for broadcasting share ratio to spoke oracles via LayerZero
 * @dev Uses Diamond storage (no inheritance from OApp to avoid storage conflicts)
 */
contract RatioBroadcastFacet {
    event RatioBroadcast(uint32 indexed dstEid, bytes32 indexed receiver, uint256 ratio);
    event PeerSet(uint32 indexed eid, bytes32 peer);
    event EndpointSet(address endpoint);

    error Unauthorized();
    error NoSharesExist();
    error NoPeer(uint32 eid);
    error InvalidEndpoint();

    /**
     * @notice Broadcast current share ratio to spoke oracle
     * @param _dstEid Destination endpoint ID
     * @param _options LayerZero messaging options
     */
    function broadcastRatio(uint32 _dstEid, bytes calldata _options) external payable {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        // Only owner or agent
        if (msg.sender != ds.owner && msg.sender != ds.agent) {
            revert Unauthorized();
        }

        // Get peer
        bytes32 receiver = ds.lzPeers[_dstEid];
        if (receiver == bytes32(0)) {
            revert NoPeer(_dstEid);
        }

        // Calculate ratio
        uint256 totalAssets = _getTotalAssets();
        uint256 totalSupply = ds.totalSupply;
        if (totalSupply == 0) {
            revert NoSharesExist();
        }

        uint256 ratio = (totalAssets * 1e18) / totalSupply;

        // Encode message
        bytes memory message = abi.encode(ratio);

        // Send via LayerZero
        MessagingParams memory params = MessagingParams({
            dstEid: _dstEid,
            receiver: receiver,
            message: message,
            options: _options,
            payInLzToken: false
        });

        ILayerZeroEndpointV2(ds.lzEndpoint).send{value: msg.value}(
            params,
            msg.sender // refund address
        );

        emit RatioBroadcast(_dstEid, receiver, ratio);
    }

    /**
     * @notice Quote fee for broadcasting ratio
     * @param _dstEid Destination endpoint ID
     * @param _options LayerZero messaging options
     * @return fee The messaging fee
     */
    function quoteBroadcastRatio(uint32 _dstEid, bytes calldata _options)
        external
        view
        returns (MessagingFee memory fee)
    {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        // Get peer
        bytes32 receiver = ds.lzPeers[_dstEid];
        if (receiver == bytes32(0)) {
            revert NoPeer(_dstEid);
        }

        // Calculate ratio
        uint256 totalAssets = _getTotalAssets();
        uint256 totalSupply = ds.totalSupply;
        uint256 ratio = totalSupply > 0 ? (totalAssets * 1e18) / totalSupply : 1e18;

        bytes memory message = abi.encode(ratio);

        MessagingParams memory params = MessagingParams({
            dstEid: _dstEid,
            receiver: receiver,
            message: message,
            options: _options,
            payInLzToken: false
        });

        fee = ILayerZeroEndpointV2(ds.lzEndpoint).quote(params, address(this));
    }

    /**
     * @notice Set LayerZero peer for destination chain
     * @param _eid Endpoint ID
     * @param _peer Peer address (bytes32)
     */
    function setPeer(uint32 _eid, bytes32 _peer) external {
        BotVaultLib.enforceIsOwner();
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        ds.lzPeers[_eid] = _peer;
        emit PeerSet(_eid, _peer);
    }

    /**
     * @notice Get peer for destination chain
     * @param _eid Endpoint ID
     * @return peer Peer address
     */
    function getPeer(uint32 _eid) external view returns (bytes32 peer) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        peer = ds.lzPeers[_eid];
    }

    /**
     * @notice Set LayerZero endpoint (one-time initialization)
     * @param _endpoint LayerZero endpoint address
     */
    function setLzEndpoint(address _endpoint) external {
        BotVaultLib.enforceIsOwner();
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();

        if (_endpoint == address(0)) {
            revert InvalidEndpoint();
        }

        // Only allow setting once (or if not set)
        require(ds.lzEndpoint == address(0), "Endpoint already set");

        ds.lzEndpoint = _endpoint;
        emit EndpointSet(_endpoint);
    }

    /**
     * @notice Get LayerZero endpoint
     * @return endpoint Endpoint address
     */
    function getLayerZeroEndpoint() external view returns (address endpoint) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        endpoint = ds.lzEndpoint;
    }

    /**
     * @notice Get current ratio info
     * @return ratio Current share-to-asset ratio (1e18 scaled)
     * @return totalAssets Total assets in vault
     * @return totalSupply Total shares issued
     */
    function getCurrentRatio() external view returns (uint256 ratio, uint256 totalAssets, uint256 totalSupply) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        totalAssets = _getTotalAssets();
        totalSupply = ds.totalSupply;
        ratio = totalSupply > 0 ? (totalAssets * 1e18) / totalSupply : 1e18;
    }

    /**
     * @notice Get total assets (local + deployed)
     * @dev Internal helper
     */
    function _getTotalAssets() internal view returns (uint256) {
        BotVaultLib.BotVaultStorage storage ds = BotVaultLib.botVaultStorage();
        uint256 localBalance = IERC20(ds.asset).balanceOf(address(this));
        uint256 deployedAmount = BotVaultLib.getTotalDeployed();
        return localBalance + deployedAmount;
    }
}
