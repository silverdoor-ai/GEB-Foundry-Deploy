pragma solidity ^0.6.7;

import {GEBDeploy} from "script/GEBDeploy.s.sol";

contract GEBDeployTest is GEBDeploy {

    bool didRun;

    function setUp() public {
        didRun = true;
    }

    function test() public {
        run();
    }
}

