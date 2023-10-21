pragma solidity >=0.6.7;

import { GebProxyActions } from "src/GebProxyActions.sol";
import "forge-std/Script.sol";

contract DeployProxyActions is Script {

    GebProxyActions public proxyActions;
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

    proxyActions = new GebProxyActions();

    console2.log("GebProxyActions deployed at: ", address(proxyActions));

    vm.stopBroadcast();

    }

    // forge script script/DeployProxyActions.s.sol:DeployProxyActions -f sepolia --broadcast --verify

}