// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUpgradeableBeacon {
    function upgradeTo(address newImplementation) external;

    function implementation() external view returns (address);
}
