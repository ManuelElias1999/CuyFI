// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {OAppSender, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {OAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IVault {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

/**
 * @title RatioBroadcaster
 * @notice Simple OApp that broadcasts share ratio from vault to spoke oracles
 * @dev Standalone contract (not a facet) - reads vault via external calls
 */
contract RatioBroadcaster is OAppSender {
    address public immutable VAULT;

    event RatioBroadcast(uint32 dstEid, uint256 ratio, uint256 timestamp);

    constructor(address _endpoint, address _vault, address _owner)
        OAppCore(_endpoint, _owner)
        Ownable(_owner)
    {
        VAULT = _vault;
    }

    /**
     * @notice Broadcast current ratio to spoke oracle
     * @param _dstEid Destination endpoint ID
     * @param _options LayerZero messaging options
     */
    function broadcastRatio(uint32 _dstEid, bytes calldata _options) external payable {
        // Read ratio from vault
        uint256 totalAssets = IVault(VAULT).totalAssets();
        uint256 totalSupply = IVault(VAULT).totalSupply();

        require(totalSupply > 0, "No shares exist");

        // Calculate ratio (scaled by 1e18)
        uint256 ratio = (totalAssets * 1e18) / totalSupply;

        // Encode message
        bytes memory message = abi.encode(ratio);

        // Send via LayerZero
        _lzSend(_dstEid, message, _options, MessagingFee(msg.value, 0), payable(msg.sender));

        emit RatioBroadcast(_dstEid, ratio, block.timestamp);
    }

    /**
     * @notice Quote fee for broadcasting
     */
    function quoteBroadcast(uint32 _dstEid, bytes calldata _options)
        external
        view
        returns (MessagingFee memory fee)
    {
        uint256 totalAssets = IVault(VAULT).totalAssets();
        uint256 totalSupply = IVault(VAULT).totalSupply();
        uint256 ratio = totalSupply > 0 ? (totalAssets * 1e18) / totalSupply : 1e18;

        bytes memory message = abi.encode(ratio);
        fee = _quote(_dstEid, message, _options, false);
    }

    function oAppVersion() public pure override returns (uint64 senderVersion, uint64 receiverVersion) {
        return (1, 1);
    }
}
