pragma solidity >=0.6.7;

import "forge-std/Script.sol";
import { Distributor } from "src/Distributor.sol";

contract DistributeETH is Script {

    string public mnemonic;
    address[] public publicKeys;
    uint256[] public privateKeys;
    Distributor public distributor;

    uint256 public chainId;

    function deriveKeys() public {
        for (uint32 i = 0; i < 10; i++) {
            (address publicKey, uint256 privateKey) = deriveRememberKey(mnemonic, i);
            publicKeys.push(publicKey);
            privateKeys.push(privateKey);
        }
    }

    function run() public {
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);
        uint256 _amount = 1 ether;

        uint256 id;
        assembly {
            id := chainid()
        }
        chainId = id;

        mnemonic = vm.envString("MNEMONIC");
        deriveKeys();

        vm.deal(deployer, _amount + 1 ether);

        distributor = new Distributor();
        console2.logUint(deployer.balance);
        (uint256 amount, address[] memory recipients) = distributor.distribute{value: _amount}(publicKeys);

        // forge script script/DistributeETH.s.sol:DistributeETH -f sepolia --broadcast --verify

    }
}