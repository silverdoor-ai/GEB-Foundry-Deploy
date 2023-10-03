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
import {Parameters} from "./parameters.s.sol";

contract GEBDeploy is Script, Parameters {

    SAFEEngine                        public safeEngine;
    TaxCollector                      public taxCollector;
    AccountingEngine                  public accountingEngine;
    LiquidationEngine                 public liquidationEngine;
    StabilityFeeTreasury              public stabilityFeeTreasury;
    Coin                              public coin;
    CoinJoin                          public coinJoin;
    BasicCollateralJoin               public basicCollateralJoin;
    RecyclingSurplusAuctionHouse      public recyclingSurplusAuctionHouse;
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

    bytes32 public collateralTypeBytes32 = bytes32("TestToken");

    uint256 chainId;

    string public protocolTokenName = vm.envString("PROTOCOL_TOKEN_NAME");
    string public protocolTokenSymbol = vm.envString("PROTOCOL_TOKEN_SYMBOL");

    string public protocolCoinName = vm.envString("PROTOCOL_COIN_NAME");
    string public protocolCoinSymbol = vm.envString("PROTOCOL_COIN_SYMBOL");

    bytes32 public mockCollateralType = bytes32("MockERC20");

    SAFEEngine.CollateralType public safeCollateralType;

    function initializeSAFEEngine() public {
        safeEngine.initializeCollateralType(collateralTypeBytes32);
        safeEngine.modifyParameters(collateralTypeBytes32, safeCollateralSafetyPrice, .5 ether);
        safeEngine.modifyParameters(collateralTypeBytes32, safeCollateralLiquidationPrice, .25 ether);
        safeEngine.modifyParameters(collateralTypeBytes32, safeCollateralDebtCeiling, uint256(-1));
        safeEngine.modifyParameters(collateralTypeBytes32, safeCollateralDebtFloor, 0);

        safeEngine.modifyParameters(safeGlobalDebtCeiling, uint256(-1));
    }

    function initializeOracleRelayer() public {
        oracleRelayer.modifyParameters(collateralTypeBytes32, relayerOracle, address(oracle));

        oracleRelayer.modifyParameters(collateralTypeBytes32, relayerSafetyCRatio, 1.5 ether);
    }

    function initializeSurplusAuctionHouse() public {
        recyclingSurplusAuctionHouse.modifyParameters(surplusAuctionHouseBidIncrease, 1.01 ether);
        recyclingSurplusAuctionHouse.modifyParameters(surplusAuctionHouseBidDuration, 15 minutes);
        recyclingSurplusAuctionHouse.modifyParameters(surplusAuctionHouseTotalAuctionLength, 30 minutes);

        recyclingSurplusAuctionHouse.modifyParameters(surplusAuctionHouseProtocolTokenBidReceiver, address(this));
    }

    function initializeDebtAuctionHouse() public {
        debtAuctionHouse.modifyParameters(debtAuctionHouseBidDecrease, 1.05 ether);
        debtAuctionHouse.modifyParameters(debtAuctionHouseAmountSoldIncrease, 1.05 ether);
        debtAuctionHouse.modifyParameters(debtAuctionHouseBidDuration, 15 minutes);
        debtAuctionHouse.modifyParameters(debtAuctionHouseTotalAuctionLength, 30 minutes);

        debtAuctionHouse.modifyParameters(debtAuctionHouseProtocolToken, address(protocolToken));
        debtAuctionHouse.modifyParameters(debtAuctionHouseAccountingEngine, address(accountingEngine));
    }

    function initializeAccountingEngine() public {
        accountingEngine.modifyParameters(accountingEngineExtraSurplusIsTransferred, 0);
        accountingEngine.modifyParameters(accountingEngineSurplusAuctionDelay, 30);
        accountingEngine.modifyParameters(accountingEnginePopDebtDelay, 30);
        accountingEngine.modifyParameters(accountingEngineDisableCooldown, 30);
        accountingEngine.modifyParameters(accountingEngineSurplusAuctionAmountToSell, 100 * RAD);
        accountingEngine.modifyParameters(accountingEngineSurplusBuffer, 1000 * RAD);
        accountingEngine.modifyParameters(accountingEngineDebtAuctionBidSize, 100 * RAD);
        accountingEngine.modifyParameters(accountingEngineInitialDebtAuctionMintedTokens, 1000 * RAD);

        accountingEngine.modifyParameters(accountingEngineSurplusAuctionHouse, address(recyclingSurplusAuctionHouse));
        accountingEngine.modifyParameters(accountingEngineDebtAuctionHouse, address(debtAuctionHouse));
        accountingEngine.modifyParameters(accountingEnginePostSettlementSurplusDrain, address(this));
        accountingEngine.modifyParameters(accountingEngineProtocolTokenAuthority, address(authority));
        accountingEngine.modifyParameters(accountingEngineExtraSurplusReceiver, address(this));
    }

    function initializeLiquidationEngine() public {
        liquidationEngine.modifyParameters(liquidationEngineOnAuctionSystemCoinLimit, 500_000 * RAD);
        liquidationEngine.modifyParameters(liquidationEngineAccountingEngine, address(accountingEngine));

        liquidationEngine.modifyParameters(collateralTypeBytes32, liquidationEngineLiquidationPenalty, 0.1 ether);
        liquidationEngine.modifyParameters(collateralTypeBytes32, liquidationEngineLiquidationQuantity, 100 * RAD);

        liquidationEngine.modifyParameters(
            collateralTypeBytes32,
            liquidationEngineCollateralAuctionHouse,
            address(englishCollateralAuctionHouse));
    }

    function initializeStabilityFeeTreasury() public {
        stabilityFeeTreasury.modifyParameters(stabilityFeeTreasuryExpensesMultiplier, 98);
        stabilityFeeTreasury.modifyParameters(stabilityFeeTreasuryTreasuryCapacity, 1_000_000e45);
        stabilityFeeTreasury.modifyParameters(stabilityFeeTreasuryMinimumFundsRequired, 100 ether);
        stabilityFeeTreasury.modifyParameters(stabilityFeeTreasuryPullFundsMinThreshold, 0);
        stabilityFeeTreasury.modifyParameters(stabilityFeeTreasurySurplusTransferDelay, 60);

        stabilityFeeTreasury.modifyParameters(stabilityFeeTreasuryExtraSurplusReceiver, address(this));
    }

    function initializeTaxCollector() public {
        taxCollector.initializeCollateralType(collateralTypeBytes32);

        taxCollector.modifyParameters(collateralTypeBytes32, taxCollectorStabilityFee, RAY);

        taxCollector.modifyParameters(taxCollectorGlobalStabilityFee, RAY);
        taxCollector.modifyParameters(taxCollectorMaxSecondaryReceivers, 2);
    }

    function initializeGlobalSettlement() public {
        globalSettlement.modifyParameters("safeEngine", address(safeEngine));
        globalSettlement.modifyParameters("liquidationEngine", address(liquidationEngine));
        globalSettlement.modifyParameters("accountingEngine", address(accountingEngine));
        globalSettlement.modifyParameters("oracleRelayer", address(oracleRelayer));
        globalSettlement.modifyParameters("coinSavingsAccount", address(coinSavingsAccount));
        globalSettlement.modifyParameters("stabilityFeeTreasury", address(stabilityFeeTreasury));

    }

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
        safeEngine.addAuthorization(address(globalSettlement));
        liquidationEngine.addAuthorization(address(globalSettlement));
        accountingEngine.addAuthorization(address(globalSettlement));

        testToken = new TestToken("TestToken", "TT", chainId);
        testToken.mintTokensTo(msg.sender, 10_000_000 ether);

        coinJoin = new CoinJoin(address(safeEngine), address(coin));
        coin.addAuthorization(address(coinJoin));

        basicCollateralJoin = new BasicCollateralJoin(address(safeEngine), collateralTypeBytes32, address(testToken));

        stabilityFeeTreasury = new StabilityFeeTreasury(address(safeEngine), msg.sender, address(coinJoin));
        stabilityFeeTreasury.addAuthorization(address(globalSettlement));

        oracleRelayer = new OracleRelayer(address(safeEngine));
        safeEngine.addAuthorization(address(oracleRelayer));
        oracleRelayer.addAuthorization(address(globalSettlement));

        taxCollector = new TaxCollector(address(safeEngine));
        safeEngine.addAuthorization(address(taxCollector));

        coinSavingsAccount = new CoinSavingsAccount(address(safeEngine));
        safeEngine.addAuthorization(address(coinSavingsAccount));
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

        // finish initialization of SAFEEngine
        initializeSAFEEngine();
        initializeOracleRelayer();
        initializeAccountingEngine();
        initializeDebtAuctionHouse();
        initializeSurplusAuctionHouse();
        initializeLiquidationEngine();
        initializeStabilityFeeTreasury();
        initializeTaxCollector();
        initializeGlobalSettlement();

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
