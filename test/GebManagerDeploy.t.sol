pragma solidity ^0.6.7;

import { GebManagerDeploy } from "script/GebManagerDeploy.s.sol";

contract GebManagerDeployTest is GebManagerDeploy {

    bool didRun;

    function setUp() public {
        didRun = true;
    }

    function test() public {
        run();
    }
}
