// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { IStakingBalanceOracle } from "./interfaces/IStakingBalanceOracle.sol";

/**
 * @title StakingBalanceOracle Contract
 * @author Open Ticketing Ecosystem
 * @notice Contract responsible for Staking balance delivery across ethereum and polygon
 */
contract StakingBalanceOracle is IStakingBalanceOracle, AuthModifiers {
    uint256 public ethereumBalance;
    uint256 public polygonBalance;

    constructor(address _registry) {
        __AuthModifiers_init(_registry);
    }

    /**
     * @notice Updates the balances of the staking contracts on ethereum and polygon
     * @param _ethereumBalance Staking balance on ethereum
     * @param _polygonBalance Staking balance on polygon
     */
    function updateStakingBalances(
        uint256 _ethereumBalance,
        uint256 _polygonBalance
    ) external onlyStakingBalanceOracle {
        ethereumBalance = _ethereumBalance;
        polygonBalance = _polygonBalance;
        emit UpdateStakingBalances(_ethereumBalance, _polygonBalance);
    }
}
