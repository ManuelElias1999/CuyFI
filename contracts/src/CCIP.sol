// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IRouterClient} from "@chainlink/contracts-ccip@1.6.2/contracts/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip@1.6.2/contracts/libraries/Client.sol";
import {OwnerIsCreator} from "@chainlink/contracts@1.5.0/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/**
 * @title Deployed CCIP Contract on Arbitrum
 * @dev This contract is deployed and verified on the Arbitrum network.
 * @notice For reference, you may review the deployment at:
 *         https://arbiscan.io/address/0x380a3af810aec334c5ccdfa7faa9c42ba9559b8e#readContract
 */
//
// Deployment Network:   Arbitrum One
// Contract Address:     0x380a3af810aec334c5ccdfa7faa9c42ba9559b8e
// Verification Link:    https://arbiscan.io/address/0x380a3af810aec334c5ccdfa7faa9c42ba9559b8e#readContract


contract TokenTransferor is OwnerIsCreator {
  using SafeERC20 for IERC20;

  error NotEnoughBalance(uint256 currentBalance, uint256 requiredBalance);
  error NothingToWithdraw();
  error FailedToWithdrawEth(address owner, address target, uint256 value);
  error DestinationChainNotAllowlisted(uint64 destinationChainSelector);
  error InvalidReceiverAddress();

  event TokensTransferred(
    bytes32 indexed messageId,
    uint64 indexed destinationChainSelector,
    address receiver,
    address token,
    uint256 tokenAmount,
    address feeToken,
    uint256 fees
  );

  mapping(uint64 => bool) public allowlistedChains;

  IRouterClient private s_router;

  IERC20 private s_linkToken;

  /// @notice Constructor sets up the router and LINK token addresses
  /// @param _router The address of the CCIP router contract
  /// @param _link The address of the LINK ERC20 token contract
  constructor(
    address _router,
    address _link
  ) {
    s_router = IRouterClient(_router);
    s_linkToken = IERC20(_link);
  }

  /// @notice Modifier to restrict execution to allowlisted destination chains only
  /// @param _destinationChainSelector The selector/ID for the destination chain
  modifier onlyAllowlistedChain(
    uint64 _destinationChainSelector
  ) {
    if (!allowlistedChains[_destinationChainSelector]) {
      revert DestinationChainNotAllowlisted(_destinationChainSelector);
    }
    _;
  }

  /// @notice Modifier to ensure the receiver address is valid (not zero)
  /// @param _receiver The address intended to receive tokens
  modifier validateReceiver(
    address _receiver
  ) {
    if (_receiver == address(0)) revert InvalidReceiverAddress();
    _;
  }

  /// @notice Allow or disallow a destination chain for cross-chain transfers
  /// @param _destinationChainSelector The selector/ID of the destination chain
  /// @param allowed Whether this chain is allowlisted (true) or not (false)
  function allowlistDestinationChain(
    uint64 _destinationChainSelector,
    bool allowed
  ) external onlyOwner {
    allowlistedChains[_destinationChainSelector] = allowed;
  }

  /// @notice Sends ERC20 tokens to another chain, paying fees in LINK
  /// @param _destinationChainSelector Selector/ID for the destination chain
  /// @param _receiver Address to receive the tokens on the destination chain
  /// @param _token The ERC20 address to send
  /// @param _amount The amount of tokens to send 
  /// @return messageId The CCIP message ID emitted by the router
  function transferTokensPayLINK(
    uint64 _destinationChainSelector,
    address _receiver,
    address _token,
    uint256 _amount
  )
    external
    onlyOwner
    onlyAllowlistedChain(_destinationChainSelector)
    validateReceiver(_receiver)
    returns (bytes32 messageId)
  {
    // Build the CCIP message to send to the router
    Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, _token, _amount, address(s_linkToken));
    // Calculate the fees required in LINK
    uint256 fees = s_router.getFee(_destinationChainSelector, evm2AnyMessage);

    uint256 requiredLinkBalance;
    // If LINK itself is being transferred, need enough LINK for fees + amount
    if (_token == address(s_linkToken)) {
      requiredLinkBalance = fees + _amount;
    } else {
      requiredLinkBalance = fees;
    }

    uint256 linkBalance = s_linkToken.balanceOf(address(this));

    // Revert if not enough LINK for the transfer+fees
    if (requiredLinkBalance > linkBalance) {
      revert NotEnoughBalance(linkBalance, requiredLinkBalance);
    }

    // Approve the router to spend LINK (for fees, or fees+amount if sending LINK)
    s_linkToken.approve(address(s_router), requiredLinkBalance);

    // If sending a different token, check for balance and approve router
    if (_token != address(s_linkToken)) {
      uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
      if (_amount > tokenBalance) {
        revert NotEnoughBalance(tokenBalance, _amount);
      }
      IERC20(_token).approve(address(s_router), _amount);
    }

    // Initiate the CCIP transfer
    messageId = s_router.ccipSend(_destinationChainSelector, evm2AnyMessage);

    // Emit transfer event for tracking
    emit TokensTransferred(messageId, _destinationChainSelector, _receiver, _token, _amount, address(s_linkToken), fees);

    return messageId;
  }

  /// @notice Sends ERC20 tokens to another chain, paying router fees in native gas token (ETH, AVAX, etc.)
  /// @param _destinationChainSelector Selector/ID for the destination chain
  /// @param _receiver Address to receive the tokens on the destination chain
  /// @param _token The ERC20 address to send
  /// @param _amount The amount of tokens to send 
  /// @return messageId The CCIP message ID emitted by the router
  function transferTokensPayNative(
    uint64 _destinationChainSelector,
    address _receiver,
    address _token,
    uint256 _amount
  )
    external
    onlyOwner
    onlyAllowlistedChain(_destinationChainSelector)
    validateReceiver(_receiver)
    returns (bytes32 messageId)
  {
    // Build the CCIP message with native fee payment
    Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, _token, _amount, address(0));
    // Calculate the fees required in native token
    uint256 fees = s_router.getFee(_destinationChainSelector, evm2AnyMessage);

    // Revert if contract doesn't have enough native token
    if (fees > address(this).balance) {
      revert NotEnoughBalance(address(this).balance, fees);
    }

    // Approve router to spend the token being sent
    IERC20(_token).approve(address(s_router), _amount);

    // Initiate the CCIP transfer, passing `fees` as native value
    messageId = s_router.ccipSend{value: fees}(_destinationChainSelector, evm2AnyMessage);

    // Emit an event to track the cross-chain transfer
    emit TokensTransferred(messageId, _destinationChainSelector, _receiver, _token, _amount, address(0), fees);

    return messageId;
  }

  /// @notice Internal helper to format a CCIP message for cross-chain transfers
  /// @param _receiver The receiver address (on destination chain)
  /// @param _token The token address to transfer
  /// @param _amount Amount of token to transfer
  /// @param _feeTokenAddress Address of the token to pay the router's CCIP fee (address(0) for native)
  /// @return CCIP formatted message to be passed to router
  function _buildCCIPMessage(
    address _receiver,
    address _token,
    uint256 _amount,
    address _feeTokenAddress
  ) private pure returns (Client.EVM2AnyMessage memory) {
    // Build single-element array for tokens to send
    Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
    tokenAmounts[0] = Client.EVMTokenAmount({token: _token, amount: _amount});

    // Pack all data into the EVM2AnyMessage struct
    return Client.EVM2AnyMessage({
      receiver: abi.encode(_receiver),
      data: "",
      tokenAmounts: tokenAmounts,
      extraArgs: Client._argsToBytes(
        Client.GenericExtraArgsV2({
          gasLimit: 0,
          allowOutOfOrderExecution: true
        })
      ),
      feeToken: _feeTokenAddress
    });
  }

  /// @notice Allow the contract to receive native token (ETH, AVAX, etc.)
  receive() external payable {}

  /// @notice Withdraws the contract's entire native token balance to a beneficiary
  /// @param _beneficiary The address to send withdrawn funds to
  function withdraw(
    address _beneficiary
  ) public onlyOwner {
    uint256 amount = address(this).balance;

    // Revert if there is nothing to withdraw
    if (amount == 0) revert NothingToWithdraw();

    // Send all native balance to the beneficiary
    (bool sent,) = _beneficiary.call{value: amount}("");

    // Revert if the transfer fails for some reason
    if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
  }

  /// @notice Withdraws the contract's full balance of a given ERC20 token to a beneficiary
  /// @param _beneficiary The address to receive the tokens
  /// @param _token ERC20 token address to withdraw
  function withdrawToken(
    address _beneficiary,
    address _token
  ) public onlyOwner {
    uint256 amount = IERC20(_token).balanceOf(address(this));

    // Revert if there are no tokens to withdraw
    if (amount == 0) revert NothingToWithdraw();

    // Transfer full balance of the token to the beneficiary
    IERC20(_token).safeTransfer(_beneficiary, amount);
  }
}