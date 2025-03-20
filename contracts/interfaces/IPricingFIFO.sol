// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPricingFIFO {
    // topup info, every topup comes a topup 'tick' (like uniswap v3 lp)
    struct TickInfo {
        uint256 price; // price of the OPN in the tick
        uint256 start; // start of the tick (in OPN units)
        uint256 stop; // end of the ticket (in OPN units)
        uint256 timestamp;
    }

    function totalTokensToppedUp() external view returns (uint256 totalTokens_);

    function totalUsdToppedUp() external view returns (uint256 totalUsd_);

    function fuelRemaining() external view returns (uint256 amountUnits_);

    function fuelBalanceUsd() external view returns (uint256 amountUnits_);

    function valueUsdOfAllTicks() external view returns (uint256 amountUnits_);

    function totalFuel() external view returns (uint256 totalFuelUsd_, uint256 totalFuelGET_);

    function overdraftEnabled() external view returns (bool);

    function inOverdraft() external view returns (bool);

    function totalUsdSpent() external view returns (uint256);

    function currentOverdraftUsd() external view returns (uint256);

    function activeTick() external view returns (TickInfo memory activeTick_);

    event RegularTopUp(uint256 counter_, TickInfo tickInfo_);
    event OverdraftTopUp(uint256 counter_, TickInfo tickInfo_);
    event CurrentActiveTick(uint256 tickIndex);
    event TickAppended(uint256 tickIndex);
    event FuelOnCredit(uint256 amountUsdToOverdraft);
}
