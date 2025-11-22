// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {OAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";
import {Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ShareOracleFacet is OAppCore {
    uint256 public cachedRatio;
    uint256 public lastUpdateTime;
    uint32 public immutable HUB_EID;
    uint256 public updateInterval = 300;

    event RatioUpdated(uint256 oldRatio, uint256 newRatio, uint256 timestamp);

    constructor(address _endpoint, uint32 _hubEid, address _owner)
        OAppCore(_endpoint, _owner)
        Ownable(_owner)
    {
        HUB_EID = _hubEid;
        cachedRatio = 1e18;
        lastUpdateTime = block.timestamp;
    }

    function getShareValueCached(uint256 shares) external view returns (uint256 assets) {
        uint256 sharesVaultFormat = shares / 1e12;
        assets = (sharesVaultFormat * cachedRatio) / 1e18;
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32,
        bytes calldata _message,
        address,
        bytes calldata
    ) internal {
        require(_origin.srcEid == HUB_EID, "Invalid source");
        uint256 newRatio = abi.decode(_message, (uint256));
        uint256 oldRatio = cachedRatio;
        cachedRatio = newRatio;
        lastUpdateTime = block.timestamp;
        emit RatioUpdated(oldRatio, newRatio, block.timestamp);
    }

    function getCachedRatioInfo() external view returns (uint256 ratio, uint256 lastUpdate, uint256 age) {
        ratio = cachedRatio;
        lastUpdate = lastUpdateTime;
        age = block.timestamp - lastUpdateTime;
    }

    function setUpdateInterval(uint256 _interval) external onlyOwner {
        updateInterval = _interval;
    }

    function oAppVersion() external pure returns (uint64 senderVersion, uint64 receiverVersion) {
        return (1, 1);
    }
}
