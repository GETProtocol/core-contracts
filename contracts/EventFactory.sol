// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { IAuth } from "./interfaces/IAuth.sol";
import { IEventFactory, IEventImplementation } from "./interfaces/IEventFactory.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IRouterRegistry } from "./interfaces/IRouterRegistry.sol";
import { IPaymentSplitterFactory } from "./interfaces/IPaymentSplitterFactory.sol";
import { IEventEmitter } from "./interfaces/IEventEmitter.sol";
import { IEventERC721CStorageProxy } from "./interfaces/IEventERC721CStorageProxy.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

/**
 * @title EventFactory Contract V2.1
 * @author Open Ticketing Ecosystem
 * @notice Contract responsible for deploying IEventImplementation contracts
 * @dev All EventImplementation contracts are deployed as Beacon Proxies
 */
contract EventFactory is IEventFactory, OwnableUpgradeable, AuthModifiers, UUPSUpgradeable {
    IRegistry private registry;
    address public storageProxyImplementation;
    UpgradeableBeacon public beacon;
    ProxyAdmin public proxyAdmin;
    IEventEmitter public eventEmitter;

    // event index => event address
    mapping(uint256 => address) public eventAddressByIndex;

    uint256 public eventCount;

    mapping(address => uint256) public eventIndexByAddress;

    IPaymentSplitterFactory public paymentSplitterFactory;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initialization function for proxy contract
     *
     * @dev A deployed EventImplementation contract is used as a beacon
     * @param _registry the Registry contract address
     * @param _implementation The EventImplementation contract address
     */
    // solhint-disable-next-line func-name-mixedcase
    function __EventFactory_init(
        address _registry,
        address _implementation,
        address _storageProxyImplementation,
        address _proxyAdminAddress
    ) external initializer {
        __Ownable_init(msg.sender);
        __AuthModifiers_init(_registry);
        __EventFactory_init_unchained(_registry, _implementation, _storageProxyImplementation, _proxyAdminAddress);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __EventFactory_init_unchained(
        address _registry,
        address _implementation,
        address _storageProxyImplementation,
        address _proxyAdminAddress
    ) internal initializer {
        registry = IRegistry(_registry);
        proxyAdmin = ProxyAdmin(_proxyAdminAddress);
        storageProxyImplementation = _storageProxyImplementation;

        beacon = new UpgradeableBeacon(_implementation, _proxyAdminAddress);

        eventEmitter = IEventEmitter(IRegistry(_registry).eventEmitterAddress());
    }

    function setPaymentSplitterFactory(address _paymentSplitterFactory) external onlyIntegratorAdmin {
        require(_paymentSplitterFactory != address(0), "EventFactory: invalid address");
        paymentSplitterFactory = IPaymentSplitterFactory(_paymentSplitterFactory);
    }

    /**
     * @notice Deploys an EventImplementation contract (using the default router of the integrator)
     * @param _name ERC721 `name`
     * @param _symbol ERC721 `symbol`
     * @param _eventData EventData struct
     */
    function createEvent(
        string memory _name,
        string memory _symbol,
        IEventImplementation.EventData memory _eventData,
        address[] calldata _payeesRoyalty,
        uint256[] calldata _sharesRoyalty,
        uint256 _royaltyFeeNumerator
    ) external onlyRelayer returns (address _eventAddress) {
        _eventAddress = _createEvent(
            _name,
            _symbol,
            _eventData,
            0,
            _payeesRoyalty,
            _sharesRoyalty,
            _royaltyFeeNumerator
        );
    }

    /**
     * @notice Deploys an EventImplementation contract (using a custom router)
     * @dev this is the function that would be called if
     * @param _name ERC721 `name`
     * @param _symbol ERC721 `symbol`
     * @param _eventData EventData struct
     * @param _routerIndex exception index of the router
     */
    function createEvent(
        string memory _name,
        string memory _symbol,
        IEventImplementation.EventData memory _eventData,
        uint256 _routerIndex,
        address[] calldata _payeesRoyalty,
        uint256[] calldata _sharesRoyalty,
        uint256 _royaltyFeeNumerator
    ) external onlyRelayer returns (address _eventAddress) {
        _eventAddress = _createEvent(
            _name,
            _symbol,
            _eventData,
            _routerIndex,
            _payeesRoyalty,
            _sharesRoyalty,
            _royaltyFeeNumerator
        );
    }

    function _createEvent(
        string memory _name,
        string memory _symbol,
        IEventImplementation.EventData memory _eventData,
        uint256 _routerIndex,
        address[] calldata _payeesRoyalty,
        uint256[] calldata _sharesRoyalty,
        uint256 _royaltyFeeNumerator
    ) internal returns (address _eventAddress) {
        TransparentUpgradeableProxy storageProxy = new TransparentUpgradeableProxy(
            storageProxyImplementation,
            address(proxyAdmin),
            ""
        );

        bytes memory _initData = abi.encodeWithSignature(
            "__EventImplementation_init(string,string,address,address)",
            _name,
            _symbol,
            address(registry),
            storageProxy
        );

        address actionsProcessor_ = address(registry.actionsProcessor());
        require(address(storageProxy) != address(0), "EventFactory: invalid storage proxy address");
        require(actionsProcessor_ != address(0), "EventFactory: invalid actions processor address");

        _eventAddress = address(
            new BeaconProxy{ salt: bytes32(uint256(_eventData.index)) }(address(beacon), _initData)
        );

        IEventERC721CStorageProxy(address(storageProxy)).initializeStorageProxy(address(registry), actionsProcessor_);

        address _paymentSplitter = paymentSplitterFactory.deployPaymentSplitter(
            _eventAddress,
            msg.sender,
            _payeesRoyalty,
            _sharesRoyalty
        );

        eventEmitter.authorizeByFactory(_eventAddress);
        eventEmitter.authorizeByFactory(_paymentSplitter);
        IEventImplementation(_eventAddress).setEventData(_eventData);
        IEventImplementation(_eventAddress).setDefaultRoyalty(_paymentSplitter, uint96(_royaltyFeeNumerator));
        registry.auth().grantEventRole(_eventAddress);
        eventAddressByIndex[_eventData.index] = _eventAddress;
        eventIndexByAddress[_eventAddress] = _eventData.index;
        IRouterRegistry _routerRegistry = registry.routerRegistry();
        address _routerAddress;
        if (_routerIndex != 0) {
            _routerAddress = _routerRegistry.registerEventToCustomRouter(_eventAddress, _routerIndex);
        } else {
            _routerAddress = _routerRegistry.registerEventToDefaultRouter(_eventAddress, msg.sender);
        }
        eventEmitter.emitEventCreated(_eventData.index, _eventAddress);
        eventEmitter.emitRouterInUse(_eventAddress, _routerAddress);
        unchecked {
            eventCount++;
        }
    }

    /**
     * @notice manually set the event financing struct
     * @param _eventAddress address of the event
     * @param _financingStruct configuration of the financing struct
     */
    function setFinancingStructOfEvent(
        address _eventAddress,
        IEventImplementation.EventFinancing memory _financingStruct
    ) external onlyProtocolDAO {
        IEventImplementation(_eventAddress).setFinancing(_financingStruct);
    }

    /**
     * @notice set the royalty of all the nfts of the event (for secondary sales on marketplaces)
     * @param _eventAddress address of the event
     * @param _receiver recipient of the collected royalty
     * @param _feeNominator amount of the royalty of the secondary ale
     */
    function setDefaultTokenRoyalty(
        address _eventAddress,
        address _receiver,
        uint96 _feeNominator
    ) external onlyRelayer {
        IEventImplementation(_eventAddress).setTokenRoyaltyDefault(_receiver, _feeNominator);
    }

    /**
     *
     * @param _eventAddress address of the event
     * @param _tokenId nftIndex of the ticket/token§
     * @param _receiver recipient address for the royalty
     * @param _feeNominator amount of royalty?
     */
    function setExceptionTokenRoyalty(
        address _eventAddress,
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNominator
    ) external onlyRelayer {
        // TODO look into this
        // IEventImplementation(_eventAddress).setTokenRoyaltyException(_tokenId, _receiver, _feeNominator);
    }

    /**
     * @notice deletes the royalty info of a specific nftIndex
     * @param _eventAddress address of the event
     * @param _tokenId nftIndex of the token to clear
     */
    function deleteRoyaltyException(address _eventAddress, uint256 _tokenId) external onlyRelayer {
        IEventImplementation(_eventAddress).deleteRoyaltyException(_tokenId);
    }

    /**
     * @notice deletes the default royalty info
     * @param _eventAddress address of the event
     */
    function deleteRoyaltyDefault(address _eventAddress) external onlyRelayer {
        IEventImplementation(_eventAddress).deleteRoyaltyInfoDefault();
    }

    /**
     * @notice returns the Event address of a particular event index
     * @param _eventIndex Index of event
     */
    function returnEventAddressByIndex(uint256 _eventIndex) external view returns (address) {
        return eventAddressByIndex[_eventIndex];
    }

    /**
     * @notice returns the Event index of a particular event address
     * @param _address Index of event
     */
    function returnEventIndexByAddress(address _address) external view returns (uint256) {
        return eventIndexByAddress[_address];
    }

    function batchActions(
        address[] calldata _eventAddressArray,
        IEventImplementation.TicketAction[][] calldata _ticketActionsArray,
        uint8[][] calldata _actionCountsArray,
        uint64[][] calldata _actionIdsArray
    ) external onlyRelayer {
        for (uint256 i; i < _eventAddressArray.length; i++) {
            IEventImplementation(_eventAddressArray[i]).batchActionsFromFactory(
                _ticketActionsArray[i],
                _actionCountsArray[i],
                _actionIdsArray[i],
                msg.sender
            );
        }
    }

    /**
     * @notice An internal function to authorize a contract upgrade
     * @dev The function is a requirement for OpenZeppelin's UUPS upgradeable contracts
     *
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Sets the event emitter address
     * @param _eventEmitter address of the event emitter contract
     * @dev can only be called by the contract owner
     */
    function setEventEmitter(address _eventEmitter) public onlyProtocolDAO {
        eventEmitter = IEventEmitter(_eventEmitter);
    }

    function upgradeBeacon(address newImplementation) external onlyOwner {
        beacon.upgradeTo(newImplementation);
    }
}
