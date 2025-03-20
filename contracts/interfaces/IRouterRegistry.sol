// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRouterRegistry {
    struct RouterInfo {
        uint256 integratorIndex;
        bool isDigitalTwinOnlyRouter;
    }

    function isRouterRegistered(address _routerAddress) external view returns (bool isRegistered_);

    function registerEventToDefaultRouter(
        address _eventAddress,
        address _relayerAddress
    ) external returns (address _routerAddress);

    function registerEventToCustomRouter(
        address _eventAddress,
        uint256 _routerIndex
    ) external returns (address _routerAddress);

    function returnEventToRouter(address _eventAddress, address _relayerAddress) external view returns (address);

    function registeredRouter(address _router) external view returns (bool);

    function setDefaultRouter(uint256 _integratorIndex, address _router) external;

    event EventRegisteredToRouter(address indexed _eventAddress, address indexed _relayerAddress);
    event DefaultRouterSet(uint256 integratorIndex, address routerAddress);
    event RegisterEventToRouterException(address indexed _eventAddress, address indexed _routerAddress);
    event RouterAddedToAllowedRouters(uint256 indexed integratorIndex_, address indexed _routerAddress);
    event RouterRemovedFromAllowedRouters(uint256 indexed integratorIndex_, address indexed _routerAddress);
    event RouterRegistered(address indexed routerAddress, RouterInfo routerInfo);
    event RouterReplaced(uint256 indexed _routerIndex, address indexed _routerAddress, RouterInfo routerInfo);
    error NoRouterRegistered(address eventAddress);
    event RouterApproved(address indexed routerAddress);
}
