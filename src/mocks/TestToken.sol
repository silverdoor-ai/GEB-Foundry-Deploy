// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.7;

import {Coin} from "geb/coin.sol";

contract TestToken is Coin {
    constructor(string memory name, string memory symbol, uint256 chainId) Coin(name, symbol, chainId) public {}

    function mintTokensTo(address user, uint256 amount) public {
        balanceOf[user] = addition(balanceOf[user], amount);
        totalSupply    = addition(totalSupply, amount);
        emit Transfer(address(0), user, amount);
    }

}