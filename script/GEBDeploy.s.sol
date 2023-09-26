// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

import "forge-std/Script.sol";
import {DSAuth, DSAuthority} from "ds-auth/auth.sol";
import {DSPause, DSPauseProxy} from "ds-pause/pause.sol";
import {DSProtestPause} from "ds-pause/protest-pause.sol";
import {DSDelegateToken} from "ds-token/delegate.sol";

import {SAFEEngine} from "geb/SAFEEngine.sol";
import {TaxCollector} from "geb/TaxCollector.sol";
import {AccountingEngine} from "geb/AccountingEngine.sol";
import {LiquidationEngine} from "geb/LiquidationEngine.sol";
import {CoinJoin, BasicCollateralJoin} from "geb/BasicTokenAdapters.sol";
import {RecyclingSurplusAuctionHouse, BurningSurplusAuctionHouse} from "geb/SurplusAuctionHouse.sol";
import {DebtAuctionHouse} from "geb/DebtAuctionHouse.sol";
import {EnglishCollateralAuctionHouse, IncreasingDiscountCollateralAuctionHouse} from "geb/CollateralAuctionHouse.sol";
import {Coin} from "geb/Coin.sol";
import {GlobalSettlement} from "geb/GlobalSettlement.sol";
import {ESM} from "esm/ESM.sol";
import {StabilityFeeTreasury} from "geb/StabilityFeeTreasury.sol";
import {CoinSavingsAccount} from "geb/CoinSavingsAccount.sol";
import {OracleRelayer} from "geb/OracleRelayer.sol";
import {DSValue} from "ds-value/value.sol";

import {TestToken} from "src/mocks/TestToken.sol";

contract GEBDeploy is Script {

    SAFEEngine                        public safeEngine;
    TaxCollector                      public taxCollector;
    AccountingEngine                  public accountingEngine;
    LiquidationEngine                 public liquidationEngine;
    StabilityFeeTreasury              public stabilityFeeTreasury;
    Coin                              public coin;
    CoinJoin                          public coinJoin;
    BasicCollateralJoin               public basicCollateralJoin;
    RecyclingSurplusAuctionHouse      public recyclingSurplusAuctionHouse;
    BurningSurplusAuctionHouse        public burningSurplusAuctionHouse;
    DebtAuctionHouse                  public debtAuctionHouse;
    OracleRelayer                     public oracleRelayer;
    CoinSavingsAccount                public coinSavingsAccount;
    GlobalSettlement                  public globalSettlement;
    ESM                               public esm;
    DSPause                           public pause;
    DSProtestPause                    public protestPause;
    DSDelegateToken                   public protocolToken;
    EnglishCollateralAuctionHouse     public englishCollateralAuctionHouse;
    TestToken                         public testToken;
    DSValue                           public oracle;
    DSAuthority                       public authority;

    bytes32 public collateralBytes32 = bytes32("TestToken");

    uint256 chainId;

    string public protocolTokenName = vm.envString("PROTOCOL_TOKEN_NAME");
    string public protocolTokenSymbol = vm.envString("PROTOCOL_TOKEN_SYMBOL");

    string public protocolCoinName = vm.envString("PROTOCOL_COIN_NAME");
    string public protocolCoinSymbol = vm.envString("PROTOCOL_COIN_SYMBOL");

    bytes32 public mockCollateralType = bytes32("MockERC20");

    function run() public {
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        uint256 id;
        assembly {
            id := chainid()
        }
        chainId = id;

        safeEngine = new SAFEEngine();

        liquidationEngine = new LiquidationEngine(address(safeEngine));
        safeEngine.addAuthorization(address(liquidationEngine));

        protocolToken = new DSDelegateToken(protocolTokenName, protocolTokenSymbol);
        protocolToken.mint(10_000_000 ether);

        coin = new Coin(protocolCoinName, protocolCoinSymbol, chainId);

        recyclingSurplusAuctionHouse = new RecyclingSurplusAuctionHouse(address(safeEngine), address(protocolToken));

        debtAuctionHouse = new DebtAuctionHouse(address(safeEngine), address(protocolToken));
        safeEngine.addAuthorization(address(debtAuctionHouse));

        accountingEngine = new AccountingEngine(
            address(safeEngine),
            address(recyclingSurplusAuctionHouse),
            address(debtAuctionHouse)
        );
        debtAuctionHouse.modifyParameters("accountingEngine", address(accountingEngine));
        recyclingSurplusAuctionHouse.addAuthorization(address(accountingEngine));
        debtAuctionHouse.addAuthorization(address(accountingEngine));
        liquidationEngine.modifyParameters("accountingEngine", address(accountingEngine));
        accountingEngine.addAuthorization(address(liquidationEngine));

        englishCollateralAuctionHouse = new EnglishCollateralAuctionHouse(
            address(safeEngine),
            address(liquidationEngine),
            mockCollateralType
        );

        globalSettlement = new GlobalSettlement();
        globalSettlement.modifyParameters("safeEngine", address(safeEngine));
        globalSettlement.modifyParameters("liquidationEngine", address(liquidationEngine));
        globalSettlement.modifyParameters("accountingEngine", address(accountingEngine));
        safeEngine.addAuthorization(address(globalSettlement));
        liquidationEngine.addAuthorization(address(globalSettlement));
        accountingEngine.addAuthorization(address(globalSettlement));

        testToken = new TestToken("TestToken", "TT", chainId);
        testToken.mintTokensTo(msg.sender, 10_000_000 ether);

        coinJoin = new CoinJoin(address(safeEngine), address(coin));
        coin.addAuthorization(address(coinJoin));

        basicCollateralJoin = new BasicCollateralJoin(address(safeEngine), collateralBytes32, address(testToken));

        stabilityFeeTreasury = new StabilityFeeTreasury(address(safeEngine), msg.sender, address(coinJoin));
        globalSettlement.modifyParameters("stabilityFeeTreasury", address(stabilityFeeTreasury));
        stabilityFeeTreasury.addAuthorization(address(globalSettlement));

        oracleRelayer = new OracleRelayer(address(safeEngine));
        safeEngine.addAuthorization(address(oracleRelayer));
        globalSettlement.modifyParameters("oracleRelayer", address(oracleRelayer));
        oracleRelayer.addAuthorization(address(globalSettlement));

        taxCollector = new TaxCollector(address(safeEngine));
        safeEngine.addAuthorization(address(taxCollector));
        taxCollector.modifyParameters("primaryTaxReceiver", address(accountingEngine));

        coinSavingsAccount = new CoinSavingsAccount(address(safeEngine));
        safeEngine.addAuthorization(address(coinSavingsAccount));
        globalSettlement.modifyParameters("coinSavingsAccount", address(coinSavingsAccount));
        coinSavingsAccount.addAuthorization(address(globalSettlement));

        oracle = new DSValue();

        esm = new ESM(
            address(protocolToken),
            address(globalSettlement),
            address(msg.sender),
            address(msg.sender),
            1_000_000 ether
        );
        globalSettlement.addAuthorization(address(esm));

        pause = new DSPause(uint256(12), address(msg.sender), authority);
        protestPause = new DSProtestPause(uint256(12), uint256(12), msg.sender, authority);

        console2.log("Deployed SAFEEngine at address: ", address(safeEngine));
        console2.log("Deployed TaxCollector at address: ", address(taxCollector));
        console2.log("Deployed AccountingEngine at address: ", address(accountingEngine));
        console2.log("Deployed LiquidationEngine at address: ", address(liquidationEngine));
        console2.log("Deployed StabilityFeeTreasury at address: ", address(stabilityFeeTreasury));
        console2.log("Deployed System Coin at address: ", address(coin));
        console2.log("Deployed CoinJoin at address: ", address(coinJoin));
        console2.log("Deployed BasicCollateralJoin at address: ", address(basicCollateralJoin));
        console2.log("Deployed RecyclingSurplusAuctionHouse at address: ", address(recyclingSurplusAuctionHouse));
        console2.log("Deployed DebtAuctionHouse at address: ", address(debtAuctionHouse));
        console2.log("Deployed OracleRelayer at address: ", address(oracleRelayer));
        console2.log("Deployed CoinSavingsAccount at address: ", address(coinSavingsAccount));
        console2.log("Deployed GlobalSettlement at address: ", address(globalSettlement));
        console2.log("Deployed ESM at address: ", address(esm));
        console2.log("Deployed DSPause at address: ", address(pause));
        console2.log("Deployed DSProtestPause at address: ", address(protestPause));
        console2.log("Deployed DSDelegateToken Protocol Token at address: ", address(protocolToken));
        console2.log("Deployed EnglishCollateralAuctionHouse at address: ", address(englishCollateralAuctionHouse));
        console2.log("Deployed TestToken at address: ", address(testToken));
        console2.log("Deployed DSValue at address: ", address(oracle));
        console2.log("Deployed MockERC20 at address: ", address(testToken));
    }

    // deploy command for Sepolia
    // forge script script/GEBDeploy.s.sol:GEBDeploy -f sepolia --broadcast --verify
}
