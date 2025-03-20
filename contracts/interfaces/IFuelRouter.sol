// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IEventImplementation } from "./IEventImplementation.sol";
import { IRegistry } from "./IRegistry.sol";
import { IAuth } from "./IAuth.sol";

interface IFuelRouter {
    enum FeeType {
        PROTOCOL,
        TREASURY,
        STAKERS
    }

    enum RouterType {
        NONE,
        DIGITAL_TWIN_ROUTER,
        WHITE_LABEL_ROUTER
    }

    struct RouteInfo {
        address fuelFrom;
        // Protocol fee route info
        address fuelToProtocol;
        // Product fee route info
        address fuelToTreasury;
        address fuelToStakers;
    }

    struct DynamicRate {
        uint64 minFeeValue;
        uint64 maxFeeValue;
        uint64 rateDynamic;
    }

    event RouteRequestFilledDTPrimarySale(
        address indexed eventAddress,
        address indexed economicsAddressFrom,
        uint256 fuelAmount,
        uint256 fuelValueUSD,
        uint256 ticketAmount
    );

    event RouteRequestFilledWLPrimarySale(
        address indexed eventAddress,
        address indexed economicsAddressFrom,
        uint256 fuelAmount,
        uint256 fuelValueUSD,
        uint256 ticketAmount
    );

    event RouteRequestFilledWLSecondarySale(
        address indexed eventAddress,
        address indexed economicsAddressFrom,
        uint256 fuelAmount,
        uint256 fuelValueUSD,
        uint256 ticketAmount
    );

    event RouteInfoChanged(RouteInfo indexed oldRoute, RouteInfo indexed newRoute);

    event RouteRequestFilled(address indexed _from, address indexed _to, uint256 _value);

    function isRouterWhitelabelRouter() external view returns (bool isWhitelabelRouter_);

    function routeFuelForPrimarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    )
        external
        returns (
            uint256 _totalFuelTokens,
            uint256 _protocolFuelTokens,
            uint256 _totalFuelUSD,
            uint256 _protocolFuelUSD
        );

    function routeFuelForSecondarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    )
        external
        returns (
            uint256 _totalFuelTokens,
            uint256 _protocolFuelTokens,
            uint256 _totalFuelUSD,
            uint256 _protocolFuelUSD
        );
}
