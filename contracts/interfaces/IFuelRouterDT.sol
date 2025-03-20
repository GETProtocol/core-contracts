// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IEventImplementation } from "./IEventImplementation.sol";
import { IFuelRouter } from "./IFuelRouter.sol";

interface IFuelRouterDT {
    function setMintBaseRate(uint256 _baseRate) external;

    event DigitalTwinFeeRoutesChanged(address indexed _economicsFrom, address indexed _fuelDestinationTo);

    event PrimaryRateProductChanged(uint64 indexed _minPrice, uint64 indexed _maxPrice, uint64 indexed _rateDynamic);
}
