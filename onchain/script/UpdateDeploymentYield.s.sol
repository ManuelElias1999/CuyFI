// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";

interface IBotStrategy {
    function updateDeploymentAmount(bytes32 deploymentId, uint256 newAmount) external;
    function getActiveDeployments() external view returns (bytes32[] memory);
    function getDeployment(bytes32 deploymentId) external view returns (
        uint32 dstEid,
        address dstVault,
        uint256 deployedAmount,
        uint256 lastUpdated
    );
}

interface IHub {
    function totalAssets() external view returns (uint256);
}

/**
 * @title UpdateDeploymentYield
 * @notice Simula yield del 10% en Aave y actualiza el deployment en el Hub
 */
contract UpdateDeploymentYield is Script {
    address constant HUB = 0x4E5cA96091B5A5E17d3Aa2178f13ad678d3874B7;

    uint256 constant ORIGINAL_AMOUNT = 500000; // 0.5 USDT que desplegamos
    uint256 constant YIELD_PERCENT = 10; // 10% yield simulado

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        console.log("===========================================");
        console.log("UPDATE DEPLOYMENT WITH YIELD");
        console.log("===========================================");
        console.log("Hub:", HUB);
        console.log("Original amount:", ORIGINAL_AMOUNT, "(0.5 USDT)");
        console.log("Simulated yield:", YIELD_PERCENT, "%");

        // Calcular nuevo monto con yield
        uint256 yieldAmount = (ORIGINAL_AMOUNT * YIELD_PERCENT) / 100;
        uint256 newAmount = ORIGINAL_AMOUNT + yieldAmount;
        console.log("Yield earned:", yieldAmount, "USDT");
        console.log("New amount:", newAmount, "USDT");

        vm.startBroadcast(pk);

        // 1. Obtener el deployment ID activo
        console.log("\n1. Getting active deployments...");
        bytes32[] memory deployments = IBotStrategy(HUB).getActiveDeployments();
        require(deployments.length > 0, "No active deployments");

        bytes32 deploymentId = deployments[0]; // Tomar el primero (nuestro deployment a Polygon)
        console.log("Deployment ID:", vm.toString(deploymentId));

        // 2. Ver estado actual del deployment
        console.log("\n2. Current deployment state:");
        (uint32 dstEid, address dstVault, uint256 currentAmount, uint256 lastUpdated) =
            IBotStrategy(HUB).getDeployment(deploymentId);

        console.log("  Destination EID:", dstEid);
        console.log("  Destination Vault:", dstVault);
        console.log("  Current Amount:", currentAmount);
        console.log("  Last Updated:", lastUpdated);

        // 3. Ver totalAssets ANTES de actualizar
        uint256 totalAssetsBefore = IHub(HUB).totalAssets();
        console.log("\n3. Total Assets BEFORE update:", totalAssetsBefore);

        // 4. Actualizar el deployment con el nuevo monto (incluyendo yield)
        console.log("\n4. Updating deployment amount...");
        IBotStrategy(HUB).updateDeploymentAmount(deploymentId, newAmount);
        console.log("Updated!");

        // 5. Ver totalAssets DESPUÉS de actualizar
        uint256 totalAssetsAfter = IHub(HUB).totalAssets();
        console.log("\n5. Total Assets AFTER update:", totalAssetsAfter);
        console.log("Increase:", totalAssetsAfter - totalAssetsBefore);

        // 6. Ver deployment actualizado
        console.log("\n6. Updated deployment state:");
        (, , uint256 updatedAmount, uint256 newTimestamp) =
            IBotStrategy(HUB).getDeployment(deploymentId);
        console.log("  New Amount:", updatedAmount);
        console.log("  New Timestamp:", newTimestamp);

        vm.stopBroadcast();

        console.log("\n===========================================");
        console.log("SUCCESS!");
        console.log("===========================================");
        console.log("Deployment updated with yield!");
        console.log("Total Assets increased from", totalAssetsBefore, "to", totalAssetsAfter);
        console.log("Yield captured:", totalAssetsAfter - totalAssetsBefore, "USDT");

        console.log("\n===========================================");
        console.log("VERIFICATION");
        console.log("===========================================");
        console.log("Users will now see the new totalAssets");
        console.log("Share value increased automatically!");
    }
}
