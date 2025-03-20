// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPriceOracle {
    event UpdatePrice(uint256 old, uint256 updated);

    function price() external view returns (uint256);

    function lastUpdateTimestamp() external view returns (uint32);

    function setPrice(uint256 _price) external;
}
