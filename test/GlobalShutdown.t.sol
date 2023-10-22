pragma solidity ^0.6.7;

import { GlobalShutdown } from "script/GlobalShutdown.s.sol";

contract GlobalShutdownTest is GlobalShutdown {

    bool didRun;

    function setUp() public {
        didRun = true;
        testRun = true;
    }

    function test() public {
        run();
    }
}