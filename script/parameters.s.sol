// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

contract Parameters {

    // Math Params
    /// @dev Max uint256 value that a RAD can represent without overflowing
    uint256 constant MAX_RAD = uint256(-1) / RAY;
    /// @dev Uint256 representation of 1 RAD
    uint256 constant RAD = 10 ** 45;
    /// @dev Uint256 representation of 1 RAY
    uint256 constant RAY = 10 ** 27;
    /// @dev Uint256 representation of 1 WAD
    uint256 constant WAD = 10 ** 18;
    /// @dev Uint256 representation of 1 year in seconds
    uint256 constant YEAR = 365 days;
    /// @dev Uint256 representation of 1 hour in seconds
    uint256 constant HOUR = 3600;

    // Safe Engine params
    // Params for collateral
    bytes32 public safeCollateralSafetyPrice = "safetyPrice";
    bytes32 public safeCollateralLiquidationPrice = "liquidationPrice";
    bytes32 public safeCollateralDebtCeiling = "debtCeiling";
    bytes32 public safeCollateralDebtFloor = "debtFloor";

    // State params
    bytes32 public safeGlobalDebtCeiling = "globalDebtCeiling";
    bytes32 public safeSafeDebtCeiling = "safeDebtCeiling";

    // Oracle Relayer params
    // Params for setting collateral oracle address
    bytes32 public relayerOracle = "orcl";

    // Params for setting collateral uint params
    bytes32 public relayerSafetyCRatio = "safetyCRatio";
    bytes32 public relayerLiquidationCRatio = "liquidationCRatio";


    // Rate params
    bytes32 public relayerRedemptionPrice = "redemptionPrice";
    bytes32 public relayerRedemptionRate = "redemptionRate";
    bytes32 public relayerRedemptionRateUpperBound = "redemptionRateUpperBound";
    bytes32 public relayerRedemptionRateLowerBound = "redemptionRateLowerBound";

    // Accounting Engine params
    // Uint256
    bytes32 public accountingEngineSurplusAuctionDelay = "surplusAuctionDelay";
    bytes32 public accountingEngineSurplusTransferDelay = "surplusTransferDelay";
    bytes32 public accountingEnginePopDebtDelay = "popDebtDelay";
    bytes32 public accountingEngineSurplusAuctionAmountToSell = "surplusAuctionAmountToSell";
    bytes32 public accountingEngineExtraSurplusIsTransferred = "extraSurplusIsTransferred";
    bytes32 public accountingEngineDebtAuctionBidSize = "debtAuctionBidSize";
    bytes32 public accountingEngineInitialDebtAuctionMintedTokens = "initialDebtAuctionMintedTokens";
    bytes32 public accountingEngineSurplusBuffer = "surplusBuffer";
    bytes32 public accountingEngineLastSurplusTransferTime = "lastSurplusTransferTime";
    bytes32 public accountingEngineLastSurplusAuctionTime = "lastSurplusAuctionTime";
    bytes32 public accountingEngineDisableCooldown = "disableCooldown";

    // address
    bytes32 public accountingEngineSurplusAuctionHouse = "surplusAuctionHouse";
    bytes32 public accountingEngineSystemStakingPool = "systemStakingPool";
    bytes32 public accountingEngineDebtAuctionHouse = "debtAuctionHouse";
    bytes32 public accountingEnginePostSettlementSurplusDrain = "postSettlementSurplusDrain";
    bytes32 public accountingEngineProtocolTokenAuthority = "protocolTokenAuthority";
    bytes32 public accountingEngineExtraSurplusReceiver = "extraSurplusReceiver";

    // Surplus Auction house params
    // uint256
    bytes32 public surplusAuctionHouseBidIncrease = "bidIncrease";
    bytes32 public surplusAuctionHouseBidDuration = "bidDuration";
    bytes32 public surplusAuctionHouseTotalAuctionLength = "totalAuctionLength";

    // address
    bytes32 public surplusAuctionHouseProtocolTokenBidReceiver = "protocolTokenBidReceiver";

    // Debt Auction house params
    // uint256
    bytes32 public debtAuctionHouseBidDecrease = "bidDecrease";
    bytes32 public debtAuctionHouseAmountSoldIncrease = "amountSoldIncrease";
    bytes32 public debtAuctionHouseBidDuration = "bidDuration";
    bytes32 public debtAuctionHouseTotalAuctionLength = "totalAuctionLength";

    // address
    bytes32 public debtAuctionHouseProtocolToken = "protocolToken";
    bytes32 public debtAuctionHouseAccountingEngine = "accountingEngine";
}