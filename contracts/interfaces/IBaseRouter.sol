// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IEventImplementation } from "./IEventImplementation.sol";

interface IBaseRouter {
    function routeFuelForPrimarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) external returns (uint256 _totalFuelValue, uint256 _totalFuelTokens);

    function routeFuelForSecondarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) external returns (uint256 _totalFuelValue, uint256 _totalFuelTokens);
}
