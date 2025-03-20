// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IEventImplementation } from "./IEventImplementation.sol";

interface IEventFactory {
    event EventCreated(uint256 indexed eventIndex, address indexed eventImplementationProxy);

    event RouterInUse(address indexed eventAddress, address indexed routerAddress);

    function eventAddressByIndex(uint256 _eventIndex) external view returns (address);

    function eventCount() external view returns (uint256);

    function createEvent(
        string memory _name,
        string memory _symbol,
        IEventImplementation.EventData memory _eventData,
        uint256 _routerIndex,
        address[] calldata _payeesRoyalty,
        uint256[] calldata _sharesRoyalty,
        uint256 _royaltyFeeNumerator
    ) external returns (address _eventAddress);

    function createEvent(
        string memory _name,
        string memory _symbol,
        IEventImplementation.EventData memory _eventData,
        address[] calldata _payeesRoyalty,
        uint256[] calldata _sharesRoyalty,
        uint256 _royaltyFeeNumerator
    ) external returns (address _eventAddress);

    function returnEventAddressByIndex(uint256 _eventIndex) external view returns (address);

    function returnEventIndexByAddress(address _address) external view returns (uint256);
}
