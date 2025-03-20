// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IPricingFIFO } from "./IPricingFIFO.sol";
import { IFuelRouter } from "./IFuelRouter.sol";

interface IEconomicsImplementation is IPricingFIFO {
    event OverdraftEnabledStatusSet(bool shouldEnableOverdraft);

    event ToppedUp(uint256 price, uint256 amount);

    event FuelReservedFromTicks(uint256 usdAmount, uint256 fuelAmount);

    event OverdraftInterestSet(uint256 indexed interestPerYear);

    function getFuelFromTicks(
        uint256 _usdAmount,
        IFuelRouter.FeeType _feeType
    ) external returns (uint256 fuelTokenAmount_);

    function topUpEconomics(uint256 _amount, uint256 _price) external returns (uint256 totalFuel_);

    function setOverdraftEnabledStatus(bool shouldEnableOverdraft) external;

    function transferFuelToCollector(
        uint256 _totalAmount,
        uint256 _protocolFuel,
        uint256 _treasuryFuel,
        uint256 _stakersFuel
    ) external;

    function fuelBalance() external view returns (uint256 fuelBalance_);

    function setFuelCollector(address _newFuelCollector) external;

    // Migration events

    event TickUpdated(uint256 indexed tickIndex, IPricingFIFO.TickInfo tickInfo);

    event UpdatedStorage(uint256 totalTokensToppedUp, uint256 totalTokensSpent);

    event MigrationComplete(uint256 getBalance, uint256 migrateBalance);

    struct MigrationData {
        TickInfo[] topUpTicks;
        uint256 activeTickIndex;
        uint256 totalTokensToppedUp;
        uint256 totalTokensSpent;
        uint256 totalUsdToppedUp;
        uint256 totalUsdSpent;
        bool overdraftEnabled;
        bool inOverdraft;
        uint256 currentOverdraftUsd;
        uint256 protocolOverdraft;
        uint256 treasuryOverdraft;
        uint256 stakersOverdraft;   
    }
}
