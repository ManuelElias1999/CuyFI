// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {OAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";
import {Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";

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
 * @title ShareOracleFacet
 * @notice Caches share ratio from Arbitrum Hub for instant, gas-free queries on spoke chains
 *
 * TODO: LayerZero ULN Configuration Issue
 * ========================================
 * Currently messages from Arbitrum Diamond are BLOCKED because this contract cannot configure
 * ULN settings (DVN verification) for receiving messages. LayerZero V2 requires the OApp contract
 * itself to call endpoint.setConfig() to specify which DVNs should verify incoming messages.
 *
 * PROBLEM:
 * - This contract inherits from OAppCore but doesn't expose setConfig wrapper
 * - Cannot configure receive-side DVNs without adding new functions
 * - Messages stuck with status "WAITING FOR ULN CONFIG" in LayerZero Scan
 *
 * SOLUTIONS:
 * Option 1 (Recommended): Add ULN config functions to this contract
 *   - Add setReceiveLibrary() wrapper
 *   - Add setUlnConfig() wrapper (similar to LayerZeroConfigFacet on Diamond)
 *   - Redeploy Oracle with new functions
 *   - Configure DVNs: LayerZero Labs + Google Cloud
 *
 * Option 2: Use LayerZero default DVNs
 *   - May work without custom config but not guaranteed
 *   - Less control over security parameters
 *
 * Option 3: Deploy new Oracle using Diamond pattern
 *   - More flexible for future upgrades
 *   - Can add/remove functionality without redeployment
 *
 * DEPLOYED:
 * - Arbitrum Diamond: 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7 (configured with DVNs ✓)
 * - Polygon Oracle: 0x416C59C8e48C4a712072f34dEfdFb6FB1d0dfC84 (needs ULN config ✗)
 *
 * REFERENCE:
 * - See LayerZeroConfigFacet.sol for example of proper ULN configuration
 * - See ConfigureDiamondOApp2.s.sol for configuration script
 */
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

    // ============ LayerZero Configuration Functions ============

    /**
     * @notice Set delegate for LayerZero endpoint configuration
     * @param _delegate Address that can configure this OApp
     */
    function setLzDelegate(address _delegate) external onlyOwner {
        endpoint.setDelegate(_delegate);
    }

    /**
     * @notice Set receive library for a specific chain
     * @param _eid Endpoint ID
     * @param _receiveLib Receive library address
     * @param _gracePeriod Grace period in seconds
     */
    function setLzReceiveLibrary(uint32 _eid, address _receiveLib, uint256 _gracePeriod) external onlyOwner {
        endpoint.setReceiveLibrary(address(this), _eid, _receiveLib, _gracePeriod);
    }

    /**
     * @notice Set ULN config with DVNs
     * @param _eid Endpoint ID
     * @param _lib Library address (send or receive)
     * @param _confirmations Number of block confirmations
     * @param _requiredDVNs Array of required DVN addresses
     */
    function setLzUlnConfig(
        uint32 _eid,
        address _lib,
        uint64 _confirmations,
        address[] calldata _requiredDVNs
    ) external onlyOwner {
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
        uint32 CONFIG_TYPE_ULN = 2;
        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = SetConfigParam({
            eid: _eid,
            configType: CONFIG_TYPE_ULN,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(address(this), _lib, params);
    }
}
