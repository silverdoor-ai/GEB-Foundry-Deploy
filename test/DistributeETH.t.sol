pragma solidity ^0.6.7;

import {DistributeETH} from "script/DistributeETH.s.sol";

contract DistributeETHTest is DistributeETH {

    bool didRun;

    function setUp() public {
        didRun = true;
    }

    function test() public {
        run();
    }
}