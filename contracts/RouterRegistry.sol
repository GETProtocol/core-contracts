// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// solhint-disable-next-line max-line-length
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { FuelRouterDT } from "./FuelRouterDT.sol";
import { FuelRouterWL } from "./FuelRouterWL.sol";
import { IRouterRegistry } from "./interfaces/IRouterRegistry.sol";
import { IFuelRouter } from "./interfaces/IFuelRouter.sol";
import { IEconomicsFactory } from "./interfaces/IEconomicsFactory.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IEventImplementation } from "./interfaces/IEventImplementation.sol";

/**
 * @title Router egistry Contract
 * @author Open Ticketing Ecosystem
 * @notice Registry for intergrator routers
 */
contract RouterRegistry is
    IRouterRegistry,
    AuthModifiers,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    IRegistry public registry;

    // routerAddress => routerInfo
    mapping(address => RouterInfo) public routerInfo;

    // routerIndex => address of a router
    mapping(uint256 => address) public routerIndexes;

    // integratorIndex => routerAddress (default router for integrator)
    mapping(uint256 => address) public defaultRouter;

    // eventAddress => RouterAddress
    mapping(address => address) public eventToRouter;

    // routerAddress => bool (is registered)
    mapping(address => bool) public registeredRouter;

    // count of registered routers
    uint256 public routerIndexCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initialization function for proxy contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __RouterRegistry_init(address _registry) public initializer {
        __Ownable_init(msg.sender);
        __AuthModifiers_init(_registry);
        __RouterRegistry_init_unchained(_registry);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __RouterRegistry_init_unchained(address _registry) public initializer {
        registry = IRegistry(_registry);
    }

    /**
     * @notice  A internal function to authorize a contract upgrade
     * @dev The function is a requirement for Openzeppelin's UUPS upgradeable contracts
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @param _eventAddress address of the event
     * @return _routerAddress address of the router that is registered to fuel the event
     */
    function returnEventToRouter(
        address _eventAddress,
        address _relayerAddress
    ) external view returns (address _routerAddress) {
        // _routerAddress = eventToRouter[_eventAddress];
        // if (_routerAddress == address(0x0)) {
        //     IEconomicsFactory _economicsFactory = registry.economicsFactory();
        //     uint256 _integratorIndex = _economicsFactory.configuredIntegratorIndex(_relayerAddress);
        //     _routerAddress = defaultRouter[_integratorIndex];

        //     if (_routerAddress == address(0x0)) {
        //         revert NoRouterRegistered(_eventAddress);
        //     }
        // }
        IEconomicsFactory _economicsFactory = registry.economicsFactory();
        uint256 _integratorIndex = _economicsFactory.configuredIntegratorIndex(_relayerAddress);
        _routerAddress = defaultRouter[_integratorIndex];
        if (_routerAddress == address(0x0)) {
            revert NoRouterRegistered(_eventAddress);
        }
    }

    /**
     * @notice Sets default router of integrator
     * @param _integratorIndex index of the integrator to configure
     * @param _routerAddress the address of the router to set the default integrator for
     */
    function setDefaultRouter(uint256 _integratorIndex, address _routerAddress) external onlyIntegratorAdmin {
        _isValidIntegrator(_integratorIndex);
        require(registeredRouter[_routerAddress], "RouterRegistry: Router not registered");
        defaultRouter[_integratorIndex] = _routerAddress;
        emit DefaultRouterSet(_integratorIndex, _routerAddress);
    }

    function isRouterRegistered(address _routerAddress) external view returns (bool _isRegistered) {
        _isRegistered = registeredRouter[_routerAddress];
    }

    /**
     * @notice  function that registers a new router to the registry
     * @dev can only be called by the integrator admin role
     * @param _routerAddress address of the router to register
     * @param _newRouterInfo router information to register
     */
    function registerNewRouter(address _routerAddress, RouterInfo memory _newRouterInfo) external onlyIntegratorAdmin {
        routerIndexCount++;
        uint128 _routerIndexCount = uint128(routerIndexCount);

        registeredRouter[_routerAddress] = true;
        routerIndexes[_routerIndexCount] = _routerAddress;
        routerInfo[_routerAddress] = _newRouterInfo;

        emit RouterRegistered(_routerAddress, _newRouterInfo);
    }

    /**
     * @notice replaces an old/existing router with a new one
     * @dev can only be called by the integrator admin role
     * @dev this may be potentially dangerous and should be used carefully
     * @param _routerIndex index of the router to replace
     * @param _routerAddress address of the router to register
     * @param _newRouterInfo router information to register
     */
    function replaceRouter(
        uint256 _routerIndex,
        address _routerAddress,
        RouterInfo memory _newRouterInfo
    ) external onlyIntegratorAdmin {
        registeredRouter[_routerAddress] = true;
        routerIndexes[_routerIndex] = _routerAddress;
        routerInfo[_routerAddress] = _newRouterInfo;

        emit RouterReplaced(_routerIndex, _routerAddress, _newRouterInfo);
    }

    /** Operational Functions */

    /**
     * @notice registers a newly deployed eventImplemplementation to the relayer that deployed it
     * @dev reason this is necessary is because a (default) router needs to be mapped to the event
     * @param _eventAddress addres of the event that was deployed
     * @param _relayerAddress address of the relayer that deployed the event
     */
    function registerEventToDefaultRouter(
        address _eventAddress,
        address _relayerAddress
    ) external onlyEventFactory returns (address _routerAddress) {
        IEconomicsFactory _economicsFactory = registry.economicsFactory();
        uint256 integratorIndex_ = _economicsFactory.configuredIntegratorIndex(_relayerAddress);

        address defaultRouter_ = defaultRouter[integratorIndex_];
        require(defaultRouter_ != address(0x0), "RouterRegistry: No default router registered for integrator");

        eventToRouter[_eventAddress] = defaultRouter_;

        emit EventRegisteredToRouter(_eventAddress, defaultRouter_);

        return defaultRouter_;
    }

    /**
     * @dev can only be called by the eventFactory on the creation of a new event (by a relayer)
     * @param _eventAddress addres of the event that was deployed
     * @param _routerIndex index of the router that should be used for the event
     */
    function registerEventToCustomRouter(
        address _eventAddress,
        uint256 _routerIndex
    ) external onlyEventFactory returns (address _routerAddress) {
        _routerAddress = routerIndexes[_routerIndex];
        require(_routerAddress != address(0x0), "RouterRegistry: Router not registered");

        eventToRouter[_eventAddress] = _routerAddress;

        emit EventRegisteredToRouter(_eventAddress, _routerAddress);
    }

    /** Internal functions */

    /**
     * @notice checks if the integrator is properly configured
     * @param _integratorIndex index of the integrator to check
     */
    function _isValidIntegrator(uint256 _integratorIndex) internal view {
        IEconomicsFactory _factory = registry.economicsFactory();
        require(_factory.isIntegratorConfigured(_integratorIndex), "RouterRegistry: Integrator not enabled/confgured");
    }
}
