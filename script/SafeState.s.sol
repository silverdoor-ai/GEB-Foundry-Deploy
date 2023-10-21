// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

import "forge-std/Script.sol";
import {ProtocolTokenAuthority} from "src/ProtocolTokenAuthority.sol";
import {DSAuth, DSAuthority} from "ds-auth/auth.sol";
import {DSPause, DSPauseProxy} from "ds-pause/pause.sol";
import {DSProtestPause} from "ds-pause/protest-pause.sol";
import {DSDelegateToken} from "ds-token/delegate.sol";
import {DSProxy, DSProxyFactory} from "src/DSProxy.sol";
import {GebProxyRegistry} from "src/GebProxyRegistry.sol";
import {GebSafeManager} from "src/GebSafeManager.sol";

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

contract SafeState is Script, Parameters {

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
    ProtocolTokenAuthority            public protocolTokenAuthority;
    DSProxyFactory                    public proxyFactory;
    GebProxyRegistry                  public gebProxyRegistry;
    GebSafeManager                    public safeManager;

    bool testRun;
    string RPC_URL;
    address deployer;
    string public mnemonic;
    address[] public publicKeys;
    uint256[] public privateKeys;
    DSProxy[] public proxies;
    uint256 chainId;

    function deployProxy(address owner) public returns (address proxy) {
        proxy = gebProxyRegistry.build(owner);
    }

    function deriveKeys() public {
        for (uint32 i = 0; i < 10; i++) {
            (address publicKey, uint256 privateKey) = deriveRememberKey(mnemonic, i);
            publicKeys.push(publicKey);
            privateKeys.push(privateKey);
        }
    }

    function deployProxies() public {
        for (uint32 i = 0; i < publicKeys.length; i++) {
            address userProxyAddress = deployProxy(publicKeys[i]);
            DSProxy userProxy = DSProxy(payable(userProxyAddress));
            proxies.push(userProxy);
        }
    }

    function dealAll() public {
        for (uint32 i = 0; i < publicKeys.length; i++) {
            vm.deal(publicKeys[i], 1 ether);
        }
        vm.deal(deployer, 1 ether);
    }

    function setEnvironment() public {
        safeEngine = SAFEEngine(vm.envAddress("SAFEENGINE"));
        taxCollector = TaxCollector(vm.envAddress("TAXCOLLECTOR"));
        accountingEngine = AccountingEngine(vm.envAddress("ACCOUNTINGENGINE"));
        liquidationEngine = LiquidationEngine(vm.envAddress("LIQUIDATIONENGINE"));
        stabilityFeeTreasury = StabilityFeeTreasury(vm.envAddress("STABILITYFEETREASURY"));
        coin = Coin(vm.envAddress("COIN"));
        coinJoin = CoinJoin(vm.envAddress("COINJOIN"));
        basicCollateralJoin = BasicCollateralJoin(vm.envAddress("BASICCOLLATERALJOIN"));
        recyclingSurplusAuctionHouse = RecyclingSurplusAuctionHouse(vm.envAddress("RECYCLINGSURPLUSAUCTIONHOUSE"));
        debtAuctionHouse = DebtAuctionHouse(vm.envAddress("DEBTAUCTIONHOUSE"));
        oracleRelayer = OracleRelayer(vm.envAddress("ORACLERELAYER"));
        coinSavingsAccount = CoinSavingsAccount(vm.envAddress("COINSAVINGSACCOUNT"));
        globalSettlement = GlobalSettlement(vm.envAddress("GLOBALSETTLEMENT"));
        esm = ESM(vm.envAddress("ESM"));
        pause = DSPause(vm.envAddress("PAUSE"));
        protestPause = DSProtestPause(vm.envAddress("PROTESTPAUSE"));
        protocolToken = DSDelegateToken(vm.envAddress("PROTOCOLTOKEN"));
        englishCollateralAuctionHouse = EnglishCollateralAuctionHouse(vm.envAddress("ENGLISHCOLLATERALAUCTIONHOUSE"));
        testToken = TestToken(vm.envAddress("TESTTOKEN"));
        oracle = DSValue(vm.envAddress("ORACLE"));
        protocolTokenAuthority = ProtocolTokenAuthority(vm.envAddress("PROTOCOLTOKENAUTHORITY"));
        proxyFactory = DSProxyFactory(vm.envAddress("PROXYFACTORY"));
        gebProxyRegistry = GebProxyRegistry(vm.envAddress("GEBPROXYREGISTRY"));
        safeManager = GebSafeManager(vm.envAddress("GEBSAFEMANAGER"));
    }

    function run() public {
        RPC_URL = vm.envString("SEPOLIA_RPC");
        mnemonic = vm.envString("MNEMONIC");
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(privKey);
        setEnvironment();
        deriveKeys();
        if (testRun) {
            console2.log(RPC_URL);
            vm.createSelectFork(RPC_URL);
            dealAll();
        }
        else {
            vm.startBroadcast(deployer);
        }

        uint256 id;
        assembly {
            id := chainid()
        }
        chainId = id;

        deployProxies();
        if (testRun == false) {
            vm.stopBroadcast();
        }

    }

}