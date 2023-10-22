pragma solidity >=0.6.7;

import "forge-std/Script.sol";
import { SAFEEngine } from "geb/SAFEEngine.sol";
import { TaxCollector } from "geb/TaxCollector.sol";

contract ThrowAway is Script {

    SAFEEngine public safeEngine;
    TaxCollector public taxCollector;
    bool testRun;
    bytes32 public collateralTypeBytes32 = bytes32("TestToken");
    string public RPC_URL;

    function run() public {
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        RPC_URL = vm.envString("SEPOLIA_RPC");
        address deployer = vm.rememberKey(privKey);
        safeEngine = SAFEEngine(vm.envAddress("SAFEENGINE"));
        taxCollector = TaxCollector(vm.envAddress("TAXCOLLECTOR"));
        if (testRun == false) {
            vm.startBroadcast(deployer);
        }
        else {
            vm.createSelectFork(RPC_URL);
            vm.startPrank(deployer);
            vm.deal(deployer, 100 ether);
        }
        taxCollector.modifyParameters("globalStabilityFee", 0);

        if (testRun == false) {
            vm.stopBroadcast();
        }
        else {
            vm.stopPrank();
        }
    }

    // forge script script/ThrowAway.s.sol:ThrowAway -f sepolia --broadcast
}
