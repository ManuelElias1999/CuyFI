// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BotVaultSpoke
 * @notice Simple spoke vault that holds USDT for yield farming on spoke chains
 * @dev Agent can deposit/withdraw USDT to/from protocols (Pendle, Aave, etc.)
 *
 * Architecture:
 * - Hub (Arbitrum): Main vault with shares (ERC4626)
 * - Spoke (Polygon/Optimism): Simple USDT holder, no shares
 *
 * Flow:
 * 1. Hub sends USDT to spoke via LayerZero
 * 2. Agent deposits USDT from spoke into protocols
 * 3. Agent harvests rewards and updates hub oracle
 * 4. Agent can withdraw USDT back to hub
 */
contract BotVaultSpoke is Ownable {
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

    // ============ Events ============

    event AgentUpdated(address indexed oldAgent, address indexed newAgent);
    event ProtocolApproved(address indexed protocol, bool approved);
    event DexApproved(address indexed dex, bool approved);
    event DepositedToProtocol(address indexed protocol, uint256 amount);
    event WithdrawnFromProtocol(address indexed protocol, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

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

    constructor(address _asset, address _agent, address _owner) Ownable(_owner) {
        if (_asset == address(0) || _agent == address(0)) revert ZeroAddress();

        ASSET = _asset;
        agent = _agent;
    }

    // ============ Owner Functions ============

    /**
     * @notice Update agent address
     */
    function setAgent(address _agent) external onlyOwner {
        if (_agent == address(0)) revert ZeroAddress();
        address oldAgent = agent;
        agent = _agent;
        emit AgentUpdated(oldAgent, _agent);
    }

    /**
     * @notice Approve/revoke a protocol for deposits
     */
    function setProtocolApproval(address protocol, bool approved) external onlyOwner {
        approvedProtocols[protocol] = approved;
        emit ProtocolApproved(protocol, approved);
    }

    /**
     * @notice Approve/revoke a DEX for swaps
     */
    function setDexApproval(address dex, bool approved) external onlyOwner {
        approvedDexs[dex] = approved;
        emit DexApproved(dex, approved);
    }

    // ============ Agent Functions ============

    /**
     * @notice Deposit USDT into a protocol (Pendle, Aave, etc.)
     * @param protocol The protocol address
     * @param amount Amount of USDT to deposit
     * @param data Encoded call data for the protocol
     */
    function depositToProtocol(
        address protocol,
        uint256 amount,
        bytes calldata data
    ) external onlyAgent {
        if (!approvedProtocols[protocol]) revert InvalidProtocol();

        // Approve protocol
        IERC20(ASSET).forceApprove(protocol, amount);

        // Execute deposit
        (bool success,) = protocol.call(data);
        require(success, "Protocol deposit failed");

        // Reset approval
        IERC20(ASSET).forceApprove(protocol, 0);

        emit DepositedToProtocol(protocol, amount);
    }

    /**
     * @notice Withdraw USDT from a protocol
     * @param protocol The protocol address
     * @param data Encoded call data for withdrawal
     */
    function withdrawFromProtocol(
        address protocol,
        bytes calldata data
    ) external onlyAgent returns (uint256 withdrawn) {
        if (!approvedProtocols[protocol]) revert InvalidProtocol();

        uint256 balanceBefore = IERC20(ASSET).balanceOf(address(this));

        // Execute withdrawal
        (bool success,) = protocol.call(data);
        require(success, "Protocol withdrawal failed");

        withdrawn = IERC20(ASSET).balanceOf(address(this)) - balanceBefore;
        emit WithdrawnFromProtocol(protocol, withdrawn);
    }

    /**
     * @notice Execute a swap on approved DEX
     * @param dex The DEX address
     * @param data Encoded swap data
     */
    function executeSwap(address dex, bytes calldata data) external onlyAgent {
        if (!approvedDexs[dex]) revert InvalidDex();

        (bool success,) = dex.call(data);
        require(success, "Swap failed");
    }

    /**
     * @notice Withdraw USDT to hub or any address
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function withdraw(address to, uint256 amount) external onlyOwnerOrAgent {
        IERC20(ASSET).safeTransfer(to, amount);
        emit Withdrawn(to, amount);
    }

    // ============ View Functions ============

    /**
     * @notice Get USDT balance held by this spoke
     */
    function balance() external view returns (uint256) {
        return IERC20(ASSET).balanceOf(address(this));
    }

    /**
     * @notice Check if protocol is approved
     */
    function isProtocolApproved(address protocol) external view returns (bool) {
        return approvedProtocols[protocol];
    }

    /**
     * @notice Check if DEX is approved
     */
    function isDexApproved(address dex) external view returns (bool) {
        return approvedDexs[dex];
    }

    // ============ Receive Function ============

    receive() external payable {}
}
