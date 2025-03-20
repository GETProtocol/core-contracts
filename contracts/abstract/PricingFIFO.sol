// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title  PricingFIFO Contract
 * @author Open Ticketing Ecosystem
 * @notice Provides logic for FIFO fuel topup and usage
 * @dev It's implemented as an abstract contract
 * @dev Fuel token, fuel and OPN are used interchangeably
 */

// solhint-disable max-states-count

import { IPricingFIFO } from "../interfaces/IPricingFIFO.sol";
import {console} from "hardhat/console.sol";

abstract contract PricingFIFO is IPricingFIFO {
    constructor() {}

    TickInfo[] public topUpTicks; // All integrator top-ups in a single array.
    uint256 public activeTickIndex; // The index of the active tick in the topUpTicks array.
    uint256 public totalTokensToppedUp; // Total sum of fuel tokens topped up for this integrator.
    uint256 public totalTokensSpent; // Sum of tokens spent by this integrator.
    uint256 public totalUsdToppedUp; // Total sum of USD topped up for this integrator.
    uint256 public totalUsdSpent; // Sum of USD topped up for this integrator.

    bool public overdraftEnabled; // Boolean status for whether overdrafts are possible for this integrator.
    bool public inOverdraft; // Has the integrator entered overdraft.
    uint256 public currentOverdraftUsd; // Current overdraft balance.

    /**
     * @notice Returns the USD value of fuel tokens left in a specific tick
     * @param _index Specific tick index
     * @return usdValue_ value left in USD
     */
    function usdValueOfTick(uint256 _index) external view returns (uint256 usdValue_) {
        return _usdValueOfTick(_index);
    }

    /**
     * @dev this is a function used for testing/auditing if the FIFO mechanism is water tight.
     * @dev Probably doesn't make sense to do it like this IRL.
     */
    function valueUsdOfAllTicks() public view returns (uint256 usdValueInTicks_) {
        for (uint256 i = activeTickIndex; i < topUpTicks.length; ++i) {
            usdValueInTicks_ += _usdValueOfTick(i);
        }
    }

    /**
     * @notice Total amout of OPN as fuel remaining (irregarless of the OPN value)
     */
    function fuelRemaining() public view returns (uint256 fuelAmount_) {
        fuelAmount_ = totalTokensToppedUp - totalTokensSpent;
    }

    /**
     * @notice Returns USD value of fuel remaining
     * @return usdValueInTicks_ usd value of all the ticks in the value
     */
    function fuelBalanceUsd() public view returns (uint256 usdValueInTicks_) {
        usdValueInTicks_ = totalUsdToppedUp - totalUsdSpent;
    }

    /**
     * @notice Returns the active tick
     */
    function activeTick() public view returns (TickInfo memory tick_) {
        tick_ = topUpTicks[activeTickIndex];
    }

    /**
     * @notice Returns the total amount of fuel in USD and OPN tokens
     * @return totalFuelUsd_ total amount of fuel in USD (of all the ticks aggregated)
     * @return totalFuelGET_ total amount of fuel in OPN (of all the ticks aggregated)
     */
    function totalFuel() public view returns (uint256 totalFuelUsd_, uint256 totalFuelGET_) {
        return (fuelBalanceUsd(), fuelRemaining());
    }

    /**
     * @notice Returns the number of top up ticks
     */
    function topUpCounter() public view returns (uint256 _numberOfTicks) {
        _numberOfTicks = topUpTicks.length;
    }

    /**
     * @notice Repays an integrator's overdraft alongside it's interest
     * @dev This is called during normal top ups in the event that an integrator is in overdraft
     * @param _amountTokens amount of tokens topped up
     * @param _pricePerToken price per token in USD
     */
    function _topUpIntegratorInOverdraft(
        uint256 _amountTokens,
        uint256 _pricePerToken
    ) internal returns (uint256 overdraftTokens_) {
        uint256 valueTopUpUsd_ = (_amountTokens * _pricePerToken) / 1e18;
        uint256 valueOverdraft_ = currentOverdraftUsd;

        console.log("valueTopUpUsd_", valueTopUpUsd_);
        console.log("valueOverdraft_", valueOverdraft_);

        require(valueTopUpUsd_ >= valueOverdraft_, "PricingFIFO: not enough topup to get out of overdraft state");

        // calculate how much tokens are used in the overdraft (in OPN units)
        overdraftTokens_ = (valueOverdraft_ * 1e18) / _pricePerToken;

        uint256 tokensLeftForNextTick_ = _amountTokens - overdraftTokens_;

        // start and stop of the topup tick (in tokens units in the totalToppedUp)
        // start is where the last (now empty) tick was deployed, to figure out the start of the new tick
        // calculate the stop of the topup tick (in tokens)
        uint256 startTick_ = topUpTicks[activeTickIndex].stop;
        uint256 stopTick_ = startTick_ + overdraftTokens_;

        // note because the integrator was in overdraft, on paper the tokens are already used
        totalTokensSpent = totalTokensToppedUp = stopTick_;
        totalUsdSpent = totalUsdToppedUp += valueOverdraft_;

        // store the topuptick info in global mapping of all topup tickets
        TickInfo memory tick_ = TickInfo(_pricePerToken, startTick_, stopTick_, block.timestamp);
        topUpTicks.push(tick_);

        delete currentOverdraftUsd;
        inOverdraft = false;
        activeTickIndex++;

        emit OverdraftTopUp(activeTickIndex, tick_);

        if (tokensLeftForNextTick_ > 0) {
            // we have tokens left to cover the next tick
            _topUpIntegrator(tokensLeftForNextTick_, _pricePerToken);
        }
    }

    /**
     * @notice Tops up an integrator with fuel at a specific price
     * @dev Top ups create a tick
     * @param _amountTokens  Amount of fuel tokens
     * @param _pricePerToken Price of fuel token
     */
    function _topUpIntegrator(uint256 _amountTokens, uint256 _pricePerToken) internal {
        uint256 newTickIndex_ = topUpTicks.length;

        // We set the start tick of the new top up to be equal to the stop point of the previous to track the handoff
        // from one to another. Skip on first run as there are no previous ticks to update.
        uint256 startTick_;
        if (newTickIndex_ != 0) {
            startTick_ = topUpTicks[newTickIndex_ - 1].stop;
        }

        uint256 stopTick_ = startTick_ + _amountTokens;

        // On first run newTickIndex should be 0.
        TickInfo memory tick_ = TickInfo(_pricePerToken, startTick_, stopTick_, block.timestamp);
        topUpTicks.push(tick_);

        // Set globals.
        totalTokensToppedUp += _amountTokens;
        totalUsdToppedUp += (_amountTokens * _pricePerToken) / 1e18;

        emit RegularTopUp(newTickIndex_, tick_);
    }

    /**
     * @dev function will only properly operate if overdrafting is enabled
     * @param _amountUsdToOverdraft amount of usd to overdraft
     */
    function _toOverdraft(uint256 _amountUsdToOverdraft) internal {
        require(overdraftEnabled, "PricingFIFO: Overdraft Disabled");

        currentOverdraftUsd += (_amountUsdToOverdraft);
        inOverdraft = true;
        emit FuelOnCredit(_amountUsdToOverdraft);
    }

    /**
     * @notice Deducts fuel tokens from the active top up tick at tick price
     * @dev will overdraft fuel tokens if fuel is exhausted in all integrator ticks (if overdraft is enabled)
     * @param _totalUsdToDeduct total amount of usd value to deduct from balance
     * @return fuelTokensUsed_ amount of OPN tokens used for the deduction
     * @return usdOverdraft_ bool indicating if the fuel demand was (partially) filled with overdrafting
     */
    function _fuelDeduction(
        uint256 _totalUsdToDeduct
    ) internal returns (uint256 fuelTokensUsed_, uint256 usdOverdraft_) {
        /**
         * In this function we use a while loop over the 'fuel demand'
         * - in each loop we use _fillFuelOrder that deducts from _totalUsdToDeduct
         *   by depleting or deducting from ticks
         * - When fuel is deducted from ticks we add the used tokens to the fuelTokensUsed_ variable
         */

        uint256 currentOverdraft_ = currentOverdraftUsd;
        uint256 currentUsdSpent_ = totalUsdSpent + currentOverdraftUsd;
        uint256 targetUsdSpent_ = currentUsdSpent_ + _totalUsdToDeduct;

        // continue filling ticks until fuel amount is filled
        while ((totalUsdSpent + currentOverdraftUsd) != targetUsdSpent_) {
            fuelTokensUsed_ += _fillFuelOrder(targetUsdSpent_ - (totalUsdSpent + currentOverdraftUsd));
        }
        return (fuelTokensUsed_, currentOverdraftUsd - currentOverdraft_);
    }

    /**
     * @notice Deduct from or drain current tick of fuel tokens at tick price(s)
     * @return amountFuelTokensUsed_ amount of OPN tokens used for the deduction loop
     */
    function _fillFuelOrder(uint256 _usdAmount) internal returns (uint256 amountFuelTokensUsed_) {
        uint256 usdValueLeft_ = _usdValueOfTick(activeTickIndex);

        // If there is nothing left the fuel will go to overdraft.
        if (usdValueLeft_ == 0) {
            _toOverdraft(_usdAmount);
            return amountFuelTokensUsed_;
        } else if (_usdAmount >= usdValueLeft_) {
            // no demand is higher as left value of active tick
            // activated tick will be emptied/drained by this fuel demanand
            amountFuelTokensUsed_ = _drainTick(_usdAmount);
            // _drainTick will activate the next tick
        } else {
            // current tick will be able to fill the fuel demand
            amountFuelTokensUsed_ = _deductFromTick(_usdAmount);
        }

        return amountFuelTokensUsed_;
    }

    /**
     * @notice Calculates the USD value of fuel tokens left in a specific tick
     * @param _index Specific tick index
     * @return usdValue_ value left in USD
     */
    function _usdValueOfTick(uint256 _index) internal view returns (uint256 usdValue_) {
        TickInfo memory tick_ = topUpTicks[_index];
        uint256 aggregated_ = totalTokensSpent;

        if (tick_.stop <= aggregated_) {
            usdValue_ = 0;
        } else if (tick_.start >= aggregated_) {
            // the tick is inactive, so we can just return the usd value of the tick
            uint256 _amount = tick_.stop - tick_.start;
            usdValue_ = (_amount * tick_.price) / 1e18;
        } else {
            uint256 range_ = tick_.stop - aggregated_;
            usdValue_ = (range_ * tick_.price) / 1e18;
        }
    }

    /**
     * @notice Deducts fuel of a tick (but doesn't drain it)
     * @return fuelTokensToBeUSed amount of tokens that was deducted/used from this tick
     * @dev this function will leave the currently activated tick activated
     * @dev unless something is wrong and it returns through if(fuelTokensUsed_ >= availableFuelTick_)
     * @dev however this should not be possible invariant wise
     */
    function _deductFromTick(uint256 _usdAmount) internal returns (uint256 fuelTokensToBeUSed) {
        uint256 activeTick_ = activeTickIndex;
        TickInfo memory tick_ = topUpTicks[activeTick_];
        // calculate how much OPN needs to be deducted from the tick using the ticks topup price
        // unlinke in _drainTick where we start by calculating how much tokens are left in the tick,
        // when this function is called we assume that the tick has enough fuel value to fill the demand
        fuelTokensToBeUSed = ((_usdAmount * 1e18) / tick_.price);
        // not sure if the scaling here is correct but the point is clear
        // amount of tokens fuel tokens left in the tick
        // note totalTokensSpent basically decides if a tick is filled or not
        uint256 availableFuelTick_ = tick_.stop - totalTokensSpent;

        if (fuelTokensToBeUSed >= availableFuelTick_) {
            // this should not be possible due to previous steps and invariants
            // but if there is not enough fuel available to fill demand in this tick
            // we should drain this tick and activate the next one!
            revert("Invariant error: fuelTokensToBeUSed >= availableFuelTick_");
        }
        // add the OPN used to to the totalTokensSpent of integrator.
        // note: by adding to this mapping we essentially use/spend the fuel!
        totalTokensSpent += fuelTokensToBeUSed;
        totalUsdSpent += _usdAmount;

        // fuel demand is fullfilled! this tick will remain active!
        return fuelTokensToBeUSed;
    }

    /**
     * @notice Drains fuel in active tick, and activates next tick
     * @return availableTokensInTick_ Returns the available tokens in tick
     */
    function _drainTick(uint256 _usdAmount) internal returns (uint256 availableTokensInTick_) {
        uint256 activeTick_ = activeTickIndex;
        TickInfo memory tick_ = topUpTicks[activeTick_];
        // amount of tokens fuel left in tick, since we will drain it
        // we need to know how much tokens are left in the tick
        availableTokensInTick_ = tick_.stop - totalTokensSpent;

        // amount of usd value of the fuel left in the tick (using the topup price of the tick)
        uint256 usdValueAvailable_ = (availableTokensInTick_ * tick_.price) / 1e18;

        if (usdValueAvailable_ > _usdAmount) {
            // this should not be possible, but to be sure, the fuel demand must completely drain this tick!
            // if the value of the fuel is more than the remaining demand, we should not drain this tick
            revert("PricingFIFO: Invariant error");
        }

        // add the OPN fuel used to to the totalTokensSpent mapping.
        // note: this is what effectively spends the fuel in this tick!
        totalTokensSpent += availableTokensInTick_;
        totalUsdSpent += usdValueAvailable_;

        if (activeTickIndex == (topUpTicks.length - 1)) {
            // this is the last tick, so we cannot activate the next tick, we just return the amount of fuel used
            uint256 usdToOverdraft_ = _usdAmount - usdValueAvailable_;
            if (usdToOverdraft_ == 0) {
                return availableTokensInTick_;
            }
            inOverdraft = true;
            _toOverdraft(usdToOverdraft_);
            return availableTokensInTick_;
        } else {
            // now this tick is  drained, we need to activate the next one!
            activeTickIndex++;

            return availableTokensInTick_;
        }
    }
}
