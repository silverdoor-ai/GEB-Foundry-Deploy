pragma solidity >=0.6.7;

import { ESM } from "esm/ESM.sol";
import { DSDelegateToken } from "ds-token/delegate.sol";
import "forge-std/Script.sol";

contract GlobalShutdown is Script {

    ESM public esm;
    DSDelegateToken public token;
    string public RPC_URL;
    bool testRun;

    function run() public {
    RPC_URL = vm.envString("SEPOLIA_RPC");
    uint256 privKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.rememberKey(privKey);
    if (testRun == false) {
        vm.startBroadcast(deployer);
    }
    else {
        vm.createSelectFork(RPC_URL);
        vm.startPrank(deployer);
    }
    esm = ESM(vm.envAddress("ESM"));
    token = DSDelegateToken(vm.envAddress("PROTOCOLTOKEN"));
    token.approve(address(esm), uint256(-1));
    esm.shutdown();
    if (testRun == false) {
        vm.stopBroadcast();
        }
    }
    // forge script script/GlobalShutdown.s.sol:GlobalShutdown -f sepolia --broadcast
}