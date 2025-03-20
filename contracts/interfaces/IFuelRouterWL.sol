// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IEventImplementation } from "./IEventImplementation.sol";
import { IFuelRouter } from "./IFuelRouter.sol";

interface IFuelRouterWL {
    function setMintBaseRate(uint256 _baseRate) external;

    function setPrimaryRateProduct(uint64 _minFeeValue, uint64 _maxFeeValue, uint64 _rateDynamic) external;

    function setSecondaryRateProduct(uint64 _minFeeValue, uint64 _maxFeeValue, uint64 _rateDynamic) external;

    event PrimarySaleRouteProtocolChanged(address indexed _from, address indexed _to);

    event PrimarySaleRouteProductChanged(address indexed _from, address indexed _to);

    event SecondarySaleRouteProtocolChanged(address indexed _from, address indexed _to);

    event SecondarySaleRouteProductChanged(address indexed _from, address indexed _to);

    event PrimaryRateProductChanged(uint64 indexed _minPrice, uint64 indexed _maxPrice, uint64 indexed _rateDynamic);

    event SecondaryRateProtocolChanged(uint64 indexed _minPrice, uint64 indexed _maxPrice, uint64 indexed _rateDynamic);

    event SecondaryRateProductChanged(uint64 indexed _minPrice, uint64 indexed _maxPrice, uint64 indexed _rateDynamic);

    event TreasuryRateUpdated(uint256 indexed treasuryRate_);
}
