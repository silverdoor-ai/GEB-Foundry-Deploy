pragma solidity >=0.6.7;

import { GebSafeManager } from "src/GebSafeManager.sol";
import "forge-std/Script.sol";

contract GebManagerDeploy is Script {

    address public safeEngine;
    GebSafeManager public safeManager;
    uint256 public chainId;

    function run() public {

    uint256 privKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.rememberKey(privKey);
    vm.startBroadcast(deployer);
    uint256 id;
    assembly {
        id := chainid()
    }
    chainId = id;

    safeEngine = vm.envAddress("SAFEENGINE");

    safeManager = new GebSafeManager(safeEngine);

    console2.log("GebSafeManager deployed at: ", address(safeManager));

    vm.stopBroadcast();

    }

    // forge script script/GebManagerDeploy.s.sol:GebManagerDeploy -f sepolia --broadcast --verify

}