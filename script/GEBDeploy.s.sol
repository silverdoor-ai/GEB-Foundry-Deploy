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
import {CoinJoin} from "geb/BasicTokenAdapters.sol";
import {RecyclingSurplusAuctionHouse, BurningSurplusAuctionHouse} from "geb/SurplusAuctionHouse.sol";
import {DebtAuctionHouse} from "geb/DebtAuctionHouse.sol";
import {EnglishCollateralAuctionHouse, IncreasingDiscountCollateralAuctionHouse} from "geb/CollateralAuctionHouse.sol";
import {Coin} from "geb/Coin.sol";
import {GlobalSettlement} from "geb/GlobalSettlement.sol";
import {ESM} from "esm/ESM.sol";
import {StabilityFeeTreasury} from "geb/StabilityFeeTreasury.sol";
import {CoinSavingsAccount} from "geb/CoinSavingsAccount.sol";
import {OracleRelayer} from "geb/OracleRelayer.sol";

import {TestToken} from "src/mocks/TestToken.sol";

contract GEBDeploy is Script {

    SAFEEngine                        public safeEngine;
    TaxCollector                      public taxCollector;
    AccountingEngine                  public accountingEngine;
    LiquidationEngine                 public liquidationEngine;
    StabilityFeeTreasury              public stabilityFeeTreasury;
    Coin                              public coin;
    CoinJoin                          public coinJoin;
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

    uint256 chainId;

    string public protocolTokenName = vm.envString("PROTOCOL_TOKEN_NAME");
    string public protocolTokenSymbol = vm.envString("PROTOCOL_TOKEN_SYMBOL");

    string public protocolCoinName = vm.envString("PROTOCOL_COIN_NAME");
    string public protocolCoinSymbol = vm.envString("PROTOCOL_COIN_SYMBOL");

    bytes32 public mockCollateralType = bytes32("MockERC20");

    function setUp() public {}

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

        protocolToken = new DSDelegateToken(protocolTokenName, protocolTokenSymbol);

        coin = new Coin(protocolCoinName, protocolCoinSymbol, chainId);

        recyclingSurplusAuctionHouse = new RecyclingSurplusAuctionHouse(address(safeEngine), address(protocolToken));

        DebtAuctionHouse debtAuctionHouse = new DebtAuctionHouse(address(safeEngine), address(protocolToken));

        AccountingEngine accountingEngine = new AccountingEngine(
            address(safeEngine),
            address(recyclingSurplusAuctionHouse),
            address(debtAuctionHouse)
        );

        englishCollateralAuctionHouse = new EnglishCollateralAuctionHouse(
            address(safeEngine),
            address(liquidationEngine),
            mockCollateralType
        );

        globalSettlement = new GlobalSettlement();

        testToken = new TestToken("TestToken", "TT", chainId);



        taxCollector = new TaxCollector(address(safeEngine));
    }
}
