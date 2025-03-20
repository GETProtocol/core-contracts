// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IFuelRouter } from "./IFuelRouter.sol";
import { IEventImplementation } from "./IEventImplementation.sol";

interface IActionsProcessor {
    function primarySale(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds,
        IFuelRouter _router
    ) external;

    function secondarySale(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds,
        IFuelRouter _router
    ) external;

    function scan(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) external;

    function checkIn(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) external;

    function invalidate(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) external;

    function claim(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) external;

    function transfer(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) external;
}
