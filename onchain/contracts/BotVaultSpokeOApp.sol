// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OApp, MessagingFee, Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";

/**
 * @title BotVaultSpokeOApp
 * @notice Spoke vault with LayerZero OApp for receiving ratio updates from Hub
 * @dev Extends OApp to receive messages + manages USDT for yield farming
 *
 * Features:
 * - Receives USDT from Hub via LayerZero OFT
 * - Receives ratio updates from Hub via LayerZero messages
 * - Agent can execute yield strategies (Aave, Pendle, etc.)
 * - Stores latest share/asset ratio from Hub
 */
contract BotVaultSpokeOApp is OApp {
    using SafeERC20 for IERC20;

    // ============ Immutables ============

    /// @notice The asset this spoke manages (USDT)
    address public immutable ASSET;

    // ============ State ============

    /// @notice Agent address (bot) authorized to manage funds
    address public agent;

    /// @notice Approved protocols for yield farming
    mapping(address => bool) public approvedProtocols;

    /// @notice Approved DEXs for swaps
    mapping(address => bool) public approvedDexs;

    /// @notice Latest share ratio from Hub (shares per asset, scaled by 1e18)
    uint256 public latestRatio;

    /// @notice Timestamp of last ratio update
    uint256 public lastRatioUpdate;

    // ============ Events ============

    event AgentUpdated(address indexed oldAgent, address indexed newAgent);
    event ProtocolApproved(address indexed protocol, bool approved);
    event DexApproved(address indexed dex, bool approved);
    event DepositedToProtocol(address indexed protocol, uint256 amount);
    event WithdrawnFromProtocol(address indexed protocol, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event RatioUpdated(uint256 ratio, uint256 timestamp);

    // ============ Errors ============

    error OnlyAgent();
    error OnlyOwnerOrAgent();
    error ZeroAddress();
    error InvalidProtocol();
    error InvalidDex();

    // ============ Modifiers ============

    modifier onlyAgent() {
        if (msg.sender != agent) revert OnlyAgent();
        _;
    }

    modifier onlyOwnerOrAgent() {
        if (msg.sender != owner() && msg.sender != agent) revert OnlyOwnerOrAgent();
        _;
    }

    // ============ Constructor ============

    /**
     * @param _asset Asset to manage (USDT)
     * @param _lzEndpoint LayerZero endpoint
     * @param _owner Owner address
     */
    constructor(
        address _asset,
        address _lzEndpoint,
        address _owner
    ) OApp(_lzEndpoint, _owner) Ownable(_owner) {
        if (_asset == address(0)) revert ZeroAddress();
        ASSET = _asset;
        agent = _owner; // Initially owner is also agent
    }

    // ============ Owner Functions ============

    function setAgent(address _agent) external onlyOwner {
        if (_agent == address(0)) revert ZeroAddress();
        address oldAgent = agent;
        agent = _agent;
        emit AgentUpdated(oldAgent, _agent);
    }

    function setProtocolApproval(address protocol, bool approved) external onlyOwner {
        approvedProtocols[protocol] = approved;
        emit ProtocolApproved(protocol, approved);
    }

    function setDexApproval(address dex, bool approved) external onlyOwner {
        approvedDexs[dex] = approved;
        emit DexApproved(dex, approved);
    }

    // ============ Agent Functions ============

    function depositToProtocol(
        address protocol,
        uint256 amount,
        bytes calldata data
    ) external onlyAgent {
        if (!approvedProtocols[protocol]) revert InvalidProtocol();

        IERC20(ASSET).forceApprove(protocol, amount);
        (bool success,) = protocol.call(data);
        require(success, "Protocol deposit failed");
        IERC20(ASSET).forceApprove(protocol, 0);

        emit DepositedToProtocol(protocol, amount);
    }

    function withdrawFromProtocol(
        address protocol,
        bytes calldata data
    ) external onlyAgent returns (uint256 withdrawn) {
        if (!approvedProtocols[protocol]) revert InvalidProtocol();

        uint256 balanceBefore = IERC20(ASSET).balanceOf(address(this));
        (bool success,) = protocol.call(data);
        require(success, "Protocol withdrawal failed");
        uint256 balanceAfter = IERC20(ASSET).balanceOf(address(this));

        withdrawn = balanceAfter - balanceBefore;
        emit WithdrawnFromProtocol(protocol, withdrawn);
    }

    function executeSwap(
        address dex,
        bytes calldata data
    ) external onlyAgent returns (bool success) {
        if (!approvedDexs[dex]) revert InvalidDex();
        (success,) = dex.call(data);
        require(success, "Swap failed");
    }

    function withdraw(address to, uint256 amount) external onlyOwnerOrAgent {
        IERC20(ASSET).safeTransfer(to, amount);
        emit Withdrawn(to, amount);
    }

    // ============ LayerZero OApp Override ============

    /**
     * @notice Receive ratio updates from Hub
     * @dev Called by LayerZero endpoint when message arrives
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        // Decode ratio from message
        uint256 ratio = abi.decode(_message, (uint256));

        // Update stored ratio
        latestRatio = ratio;
        lastRatioUpdate = block.timestamp;

        emit RatioUpdated(ratio, block.timestamp);
    }

    // ============ View Functions ============

    function balance() external view returns (uint256) {
        return IERC20(ASSET).balanceOf(address(this));
    }

    function isProtocolApproved(address protocol) external view returns (bool) {
        return approvedProtocols[protocol];
    }

    function isDexApproved(address dex) external view returns (bool) {
        return approvedDexs[dex];
    }

    /**
     * @notice Get latest ratio and when it was updated
     */
    function getRatio() external view returns (uint256 ratio, uint256 timestamp) {
        return (latestRatio, lastRatioUpdate);
    }
}
