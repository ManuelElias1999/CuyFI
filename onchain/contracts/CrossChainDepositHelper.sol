// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IOFT, SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

/**
 * @title CrossChainDepositHelper
 * @notice Helper contract to simplify cross-chain deposits for users
 * @dev This makes it easy to call from cast or frontend
 */
contract CrossChainDepositHelper {
    using OptionsBuilder for bytes;

    address public immutable USDT_OFT_POLYGON;
    address public immutable COMPOSER_ARBITRUM;

    uint32 constant ARBITRUM_EID = 30110;
    uint32 constant POLYGON_EID = 30109;

    constructor(address _usdtOft, address _composer) {
        USDT_OFT_POLYGON = _usdtOft;
        COMPOSER_ARBITRUM = _composer;
    }

    /**
     * @notice Deposit USDT from Polygon, receive shares on Polygon
     * @param amount Amount of USDT to deposit (6 decimals)
     * @param minShares Minimum shares to receive (slippage protection)
     * @dev User must approve this contract to spend USDT first
     */
    function depositCrossChain(uint256 amount, uint256 minShares) external payable {
        address user = msg.sender;

        // Transfer USDT from user
        IERC20(IOFT(USDT_OFT_POLYGON).token()).transferFrom(user, address(this), amount);

        // Approve OFT
        IERC20(IOFT(USDT_OFT_POLYGON).token()).approve(USDT_OFT_POLYGON, amount);

        // Build hopSendParam (for sending shares back)
        SendParam memory hopSendParam = SendParam({
            dstEid: POLYGON_EID,
            to: bytes32(uint256(uint160(user))),
            amountLD: 0, // Will be set by composer
            minAmountLD: 0,
            extraOptions: hex"",
            composeMsg: hex"",
            oftCmd: hex""
        });

        // Encode compose message
        // For now, composer will NOT receive ETH - let's test if deposit works without return trip
        uint256 minMsgValue = 0;
        bytes memory composeMsg = abi.encode(hopSendParam, minShares, minMsgValue);

        // Build extraOptions following LayerZero documentation examples
        bytes memory extraOptions = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(200000, 0)      // Gas for lzReceive (token transfer + queue compose)
            .addExecutorLzComposeOption(0, 500000, 0);  // Gas for lzCompose (deposit logic)

        // Build USDT sendParam
        SendParam memory usdtSendParam = SendParam({
            dstEid: ARBITRUM_EID,
            to: bytes32(uint256(uint160(COMPOSER_ARBITRUM))),
            amountLD: amount,
            minAmountLD: amount,
            extraOptions: extraOptions,
            composeMsg: composeMsg,
            oftCmd: hex""
        });

        // Send via LayerZero
        IOFT(USDT_OFT_POLYGON).send{value: msg.value}(
            usdtSendParam,
            MessagingFee(msg.value, 0),
            user // Refund address
        );
    }

    /**
     * @notice Quote the fee for a cross-chain deposit
     * @param amount Amount of USDT to deposit
     * @return nativeFee POL required for the transaction
     */
    function quoteFee(uint256 amount) external view returns (uint256 nativeFee) {
        // Build params (same as depositCrossChain)
        SendParam memory hopSendParam = SendParam({
            dstEid: POLYGON_EID,
            to: bytes32(uint256(uint160(msg.sender))),
            amountLD: 0,
            minAmountLD: 0,
            extraOptions: hex"",
            composeMsg: hex"",
            oftCmd: hex""
        });

        uint256 minMsgValue = 0;
        bytes memory composeMsg = abi.encode(hopSendParam, 0, minMsgValue);

        // Build extraOptions using OptionsBuilder
        bytes memory extraOptions = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(200000, 0)
            .addExecutorLzComposeOption(0, 500000, 0);

        SendParam memory usdtSendParam = SendParam({
            dstEid: ARBITRUM_EID,
            to: bytes32(uint256(uint160(COMPOSER_ARBITRUM))),
            amountLD: amount,
            minAmountLD: amount,
            extraOptions: extraOptions,
            composeMsg: composeMsg,
            oftCmd: hex""
        });

        MessagingFee memory fee = IOFT(USDT_OFT_POLYGON).quoteSend(usdtSendParam, false);
        // The fee already includes the cost of passing minMsgValue to composer
        // Just add small buffer for price fluctuations
        return fee.nativeFee + 0.1 ether;
    }
}
