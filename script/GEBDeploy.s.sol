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
        safeEngine.addAuthorization(address(liquidationEngine));

        protocolToken = new DSDelegateToken(protocolTokenName, protocolTokenSymbol);

        coin = new Coin(protocolCoinName, protocolCoinSymbol, chainId);

        recyclingSurplusAuctionHouse = new RecyclingSurplusAuctionHouse(address(safeEngine), address(protocolToken));

        DebtAuctionHouse debtAuctionHouse = new DebtAuctionHouse(address(safeEngine), address(protocolToken));
        safeEngine.addAuthorization(address(debtAuctionHouse));

        AccountingEngine accountingEngine = new AccountingEngine(
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
            uint256(5000000)
        );
        globalSettlement.addAuthorization(address(esm));

        pause = new DSPause(uint256(12), address(msg.sender), authority);
    }
}
