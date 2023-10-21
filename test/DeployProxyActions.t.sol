pragma solidity ^0.6.7;

import { DeployProxyActions } from "script/DeployProxyActions.s.sol";

contract DeployProxyActionsTest is DeployProxyActions {

    bool didRun;

    function setUp() public {
        didRun = true;
    }

    function test() public {
        run();
    }
}