// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStakingBalanceOracle {
    event UpdateStakingBalances(uint256 ethereumBalance, uint256 polygonBalance);

    function ethereumBalance() external view returns (uint256);

    function polygonBalance() external view returns (uint256);

    function updateStakingBalances(uint256 _ethereumBalance, uint256 _polygonBalance) external;
}
