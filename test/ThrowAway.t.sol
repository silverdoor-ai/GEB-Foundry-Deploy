pragma solidity ^0.6.7;

import {ThrowAway} from "script/ThrowAway.s.sol";

contract ThrowAwayTest is ThrowAway {

    bool didRun;

    function setUp() public {
        didRun = true;
        testRun = true;
    }

    function test() public {
        run();
    }
}