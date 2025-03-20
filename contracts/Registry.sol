//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
// solhint-disable-next-line max-line-length
import { IRegistry, IAuth, IPriceOracle, ITopUp, IRouterRegistry, IEconomicsFactory, IEventFactory, IFuelCollector, IStakingBalanceOracle, IActionsProcessor } from "./interfaces/IRegistry.sol";
import { IEconomics } from "./test/interfaces/IEconomics.sol";
import { IPaymentSplitterFactory } from "./interfaces/IPaymentSplitterFactory.sol";
import { IEventEmitter } from "./interfaces/IEventEmitter.sol";
/**
 * @title Registry Contract
 * @author Open Ticketing Ecosystem
 * @notice Registry for protocol-wide global variables
 */
contract Registry is IRegistry, Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using Address for address;

    IAuth public auth;
    address public economics; // storage slot for legacy economics
    IEventFactory public eventFactory;
    IPriceOracle public priceOracle;
    address public fuelDistributor; // storage slot for legacy fuel distributor
    ITopUp public topUp;
    string public baseURI;

    IRouterRegistry public routerRegistry;
    IEconomicsFactory public economicsFactory;
    IFuelCollector public fuelCollector;
    IStakingBalanceOracle public stakingBalanceOracle;

    address public protocolFeeDestination;
    address public treasuryFeeDestination;
    address public stakingContractAddress;
    address public fuelBridgeReceiverAddress;
    IActionsProcessor public actionsProcessor;
    IPaymentSplitterFactory public paymentSplitterFactory;
    IEventEmitter public eventEmitter;

    mapping(address => bool) public isValidTicketRouter;

    address public eventERC721CStorageProxyImplementation;

    function setIsValidTicketRouter(address _ticketRouter, bool _isValid) external onlyOwner {
        isValidTicketRouter[_ticketRouter] = _isValid;
        emit UpdateIsValidTicketRouter(_ticketRouter, _isValid);
    }

    function isValidTicketRouterReturn(address _ticketRouter) external view returns (bool) {
        return isValidTicketRouter[_ticketRouter];
    }

    function isValidTicketRouterCheck(address _ticketRouter) external view {
        require(isValidTicketRouter[_ticketRouter], "Registry: ticket router not valid");
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initialization function for proxy contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Registry_init() public initializer {
        __Context_init();
        __Ownable_init(msg.sender);
        __Registry_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Registry_init_unchained() public initializer {}

    /**
     * @notice Sets the Auth contract address
     * @dev Would throw if `_auth` is not a contract address
     *
     * @dev can only be called by contract owner
     * @param _auth Auth contract address
     */
    function setAuth(address _auth) external isContract(_auth) onlyOwner {
        emit UpdateAuth(address(auth), _auth);
        auth = IAuth(_auth);
    }

    /**
     * @notice Sets the PriceOracle contract address
     * @dev Would throw if `_priceOracle` is not a contract address
     *
     * @dev can only be called by contract owner
     * @param _priceOracle PriceOracle contract address
     */
    function setPriceOracle(address _priceOracle) external isContract(_priceOracle) onlyOwner {
        emit UpdatePriceOracle(address(priceOracle), _priceOracle);
        priceOracle = IPriceOracle(_priceOracle);
    }

    /**
     * @notice Sets the EventEmitter contract address
     * @dev Would throw if `_eventEmitter` is not a contract address
     *
     * @dev can only be called by contract owner
     * @param _eventEmitter EventEmitter contract address
     */
    function setEventEmitter(address _eventEmitter) external isContract(_eventEmitter) onlyOwner {
        emit UpdateEventEmitter(address(eventEmitter), _eventEmitter);
        eventEmitter = IEventEmitter(_eventEmitter);
    }

    /**
     * @notice Sets the StakingBalanceOracle contract address
     * @dev Would throw if `_stakingBalanceOracle` is not a contract address
     *
     * @dev can only be called by contract owner
     * @param _stakingBalanceOracle StakingBalanceOracle contract address
     */
    function setStakingBalanceOracle(
        address _stakingBalanceOracle
    ) external isContract(_stakingBalanceOracle) onlyOwner {
        emit UpdateStakingBalanceOracle(address(stakingBalanceOracle), _stakingBalanceOracle);
        stakingBalanceOracle = IStakingBalanceOracle(_stakingBalanceOracle);
    }

    function setRouterRegistry(address _routerRegistry) external isContract(_routerRegistry) onlyOwner {
        emit UpdateRouterRegistry(address(routerRegistry), _routerRegistry);
        routerRegistry = IRouterRegistry(_routerRegistry);
    }

    function setEconomicsFactory(address _economicsFactory) external isContract(_economicsFactory) onlyOwner {
        emit UpdateEconomicsFactory(address(economicsFactory), _economicsFactory);
        economicsFactory = IEconomicsFactory(_economicsFactory);
    }

    function setEventFactory(address _eventFactoryV2) external isContract(_eventFactoryV2) onlyOwner {
        emit UpdateEventFactoryV2(address(eventFactory), _eventFactoryV2);
        eventFactory = IEventFactory(_eventFactoryV2);
    }

    /**
     * @notice Sets the TopUp contract address
     * @dev Would throw if `_topUp` is not a contract address
     *
     * @dev can only be called by contract owner
     * @param _topUp TopUp contract address
     */
    function setTopUp(address _topUp) external isContract(_topUp) onlyOwner {
        emit UpdateTopUp(address(topUp), _topUp);
        topUp = ITopUp(_topUp);
    }

    /**
     * @notice Sets the FuelCollector contract address
     * @dev Would throw if `_fuelCollector` is not a contract address
     *
     * @dev can only be called by contract owner
     * @param _fuelCollector FuelCollector contract address
     */
    function setFuelCollector(address _fuelCollector) external isContract(_fuelCollector) onlyOwner {
        emit UpdateFuelCollector(address(fuelCollector), _fuelCollector);
        fuelCollector = IFuelCollector(_fuelCollector);
    }

    function setActionsProcessor(address _actionsProcessor) external isContract(_actionsProcessor) onlyOwner {
        emit UpdateActionsProcessor(_actionsProcessor);
        actionsProcessor = IActionsProcessor(_actionsProcessor);
    }

    /**
     * @notice Sets the PaymentSplitterFactory contract address
     * @dev Would throw if `_paymentSplitterFactory` is not a contract address
     *
     * @dev can only be called by contract owner
     * @param _paymentSplitterFactory PaymentSplitterFactory contract address
     */
    function setPaymentSplitterFactory(
        address _paymentSplitterFactory
    ) external isContract(_paymentSplitterFactory) onlyOwner {
        emit UpdatePaymentSplitterFactory(address(paymentSplitterFactory), _paymentSplitterFactory);
        paymentSplitterFactory = IPaymentSplitterFactory(_paymentSplitterFactory);
    }

    /**
     * @notice Sets the Base URI
     *
     * @dev The base URI is used to derive a token's URI on an EventImplementation contract
     * @dev can only be called by contract owner
     * @param _baseURI Base URI
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        emit UpdateBaseURI(baseURI, _baseURI);
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the protocol fee destination Address
     *
     * @dev All protocol fees are sent to this address
     * @dev can only be called by contract owner
     * @param _feeDestination protocol fee destination
     */
    function setProtocolFeeDestination(address _feeDestination) external onlyOwner {
        emit UpdateProtocolFeeDestination(_feeDestination);
        protocolFeeDestination = _feeDestination;
    }

    /**
     * @notice Sets the treasury fee destination Address
     *
     * @dev All treasury fees are sent to this address
     * @dev can only be called by contract owner
     * @param _feeDestination treasury fee destination
     */
    function setTreasuryFeeDestination(address _feeDestination) external onlyOwner {
        emit UpdateTreasuryFeeDestination(_feeDestination);
        treasuryFeeDestination = _feeDestination;
    }

    /**
     * @notice Sets the staking contract address
     *
     * @dev All stakers fee for polygon are sent to this address
     * @dev can only be called by contract owner
     * @param _contractAddress staking contract address
     */
    function setStakingContractAddress(address _contractAddress) external onlyOwner {
        emit UpdateStakingContractAddress(_contractAddress);
        stakingContractAddress = _contractAddress;
    }

    /**
     * @notice Sets the fuel bridge receiver address
     *
     * @dev All stakers fee for ethereum are sent to this address
     * @dev can only be called by contract owner
     * @param _fuelBridgeReceiverAddress fuel bridge receiver address
     */
    function setFuelBridgeReceiverAddress(address _fuelBridgeReceiverAddress) external onlyOwner {
        emit UpdateFuelBridgeReceiverAddress(_fuelBridgeReceiverAddress);
        fuelBridgeReceiverAddress = _fuelBridgeReceiverAddress;
    }

    /**
     * @dev Filters out non-contract addresses
     */
    modifier isContract(address _account) {
        require(_account.code.length > 0, "Registry: address not a contract");
        _;
    }

    function eventEmitterAddress() external view returns (address) {
        return address(eventEmitter);
    }

    /**
     * @notice  A internal function to authorize a contract upgrade
     * @dev The function is a requirement for Openzeppelin's UUPS upgradeable contracts
     *
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setEventERC721CStorageProxyImplementation(address _implementation) external onlyOwner {
        emit UpdateEventERC721CStorageProxyImplementation(eventERC721CStorageProxyImplementation, _implementation);
        eventERC721CStorageProxyImplementation = _implementation;
    }

    event UpdateEventERC721CStorageProxyImplementation(address oldImplementation, address newImplementation);
}
