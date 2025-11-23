// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBotVaultSpoke {
    function setProtocolApproval(address protocol, bool approved) external;
    function depositToProtocol(
        address protocol,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IAaveAdapter {
    function stake(uint256 amount, bytes calldata data) external returns (uint256);
}

/**
 * @title DepositToAavePolygon
 * @notice Deposit the 0.5 USDT from Polygon Spoke to Aave
 */
contract DepositToAavePolygon is Script {
    address constant SPOKE = 0x4Bf635A68d392Aa5A9e53a7c537637C73D6a4300;
    address constant AAVE_ADAPTER = 0x568f8af8c57a662a2DEa771F91Bc49d1d09a5416;
    address constant USDT_POLYGON = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    uint256 constant AMOUNT = 500000; // 0.5 USDT

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        console.log("===========================================");
        console.log("DEPOSIT TO AAVE ON POLYGON");
        console.log("===========================================");
        console.log("Spoke:", SPOKE);
        console.log("Aave Adapter:", AAVE_ADAPTER);
        console.log("Amount:", AMOUNT, "(0.5 USDT)");

        vm.startBroadcast(pk);

        // Check current balance
        uint256 spokeBalance = IERC20(USDT_POLYGON).balanceOf(SPOKE);
        console.log("\n1. Current Spoke USDT balance:", spokeBalance);
        require(spokeBalance >= AMOUNT, "Insufficient balance");

        // Approve Aave Adapter as protocol
        console.log("\n2. Approving Aave Adapter...");
        IBotVaultSpoke(SPOKE).setProtocolApproval(AAVE_ADAPTER, true);
        console.log("Approved!");

        // Encode stake call
        bytes memory depositData = abi.encodeWithSelector(
            IAaveAdapter.stake.selector,
            AMOUNT,          // amount
            bytes("")        // empty data
        );

        // Execute via Spoke
        console.log("\n3. Depositing to Aave...");
        IBotVaultSpoke(SPOKE).depositToProtocol(AAVE_ADAPTER, AMOUNT, depositData);
        console.log("Deposited!");

        // Check balance after
        uint256 newBalance = IERC20(USDT_POLYGON).balanceOf(SPOKE);
        console.log("\n4. New Spoke USDT balance:", newBalance);
        console.log("Amount deposited:", spokeBalance - newBalance);

        vm.stopBroadcast();

        console.log("\n===========================================");
        console.log("SUCCESS!");
        console.log("===========================================");
        console.log("Deposited:", AMOUNT, "USDT to Aave");
        console.log("\nCheck aToken balance:");
        console.log("cast call 0x6ab707Aca953eDAeFBc4fD23bA73294241490620 \"balanceOf(address)(uint256)\"", AAVE_ADAPTER, "--rpc-url https://polygon-rpc.com");
    }
}
