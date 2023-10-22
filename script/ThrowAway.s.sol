pragma solidity >=0.6.7;

import "forge-std/Script.sol";
import { SAFEEngine } from "geb/SAFEEngine.sol";
import { TaxCollector } from "geb/TaxCollector.sol";
import { ThresholdSetter } from "src/mocks/ThresholdSetter.sol";
import { ESM } from "esm/ESM.sol";

contract ThrowAway is Script {

    SAFEEngine public safeEngine;
    TaxCollector public taxCollector;
    ThresholdSetter public thresholdSetter;
    ESM public esm;
    bool testRun;
    bytes32 public collateralTypeBytes32 = bytes32("TestToken");
    string public RPC_URL;

    function run() public {
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        RPC_URL = vm.envString("SEPOLIA_RPC");
        address deployer = vm.rememberKey(privKey);
        safeEngine = SAFEEngine(vm.envAddress("SAFEENGINE"));
        taxCollector = TaxCollector(vm.envAddress("TAXCOLLECTOR"));
        esm = ESM(vm.envAddress("ESM"));
        if (testRun == false) {
            vm.startBroadcast(deployer);
        }
        else {
            vm.createSelectFork(RPC_URL);
            vm.startPrank(deployer);
            vm.deal(deployer, 100 ether);
        }
        thresholdSetter = new ThresholdSetter();
        esm.modifyParameters("thresholdSetter", address(thresholdSetter));

        if (testRun == false) {
            vm.stopBroadcast();
        }
        else {
            vm.stopPrank();
        }
    }

    // forge script script/ThrowAway.s.sol:ThrowAway -f sepolia --broadcast
}
