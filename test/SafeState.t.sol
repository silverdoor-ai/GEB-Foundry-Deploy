pragma solidity ^0.6.7;

import {SafeState} from "script/SafeState.s.sol";

contract SafeStateTest is SafeState {

    bool didRun;

    function setUp() public {
        didRun = true;
    }

    function test() public {
        run();
    }
}