// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// solhint-disable-next-line max-line-length
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { IRegistry, IFuelCollector, IRouterRegistry } from "./interfaces/IRegistry.sol";
import { IEconomicsFactory, IERC20 } from "./interfaces/IEconomicsFactory.sol";
import { IEconomicsImplementation } from "./interfaces/IEconomicsImplementation.sol";
import { IEconomics } from "./test/interfaces/IEconomics.sol";
import { IEconomicsMigrator } from "./interfaces/IEconomicsMigrator.sol";
import { IEventEmitter } from "./interfaces/IEventEmitter.sol";
/**
 * @title EconomicsFactory Contract
 * @author OPN Ticketing Ecosystem
 * @notice Contract responsible for deploying EconomicsImplementation contracts per integrator
 * @dev Acts as singular entry point for accounting operations for integrtors
 */
contract EconomicsFactory is
    IEconomicsFactory,
    OwnableUpgradeable,
    AuthModifiers,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    IRegistry private registry;
    UpgradeableBeacon public beacon;
    DynamicRates public protocolRates;
    IERC20 public fuelToken;

    // relayerAddres => RelayerData (integratorIndex)
    mapping(address => RelayerData) public relayerData;

    // integratorIndex => IntegratorData
    mapping(uint256 => IntegratorData) public integratorData;

    // integratorIndex => DynamicRates
    mapping(uint256 => DynamicRates) public integratorRates;

    // integratorIndex => bool (true = digital twin type of integrator, false = whitelabel type of integrator)
    mapping(uint256 => bool) public isDigitalTwin;

    // integratorIndex => economicsAddress
    mapping(uint256 => address) public economicsContracts;

    // economicsAddress => integratorIndex
    mapping(address => uint256) public economicsToIndex;

    // count (including old integrators)
    uint256 public integratorCount;

    // determines if data has been migrated from legacy Economics contract
    bool public migrated;

    bool public wasUpgradeSuccessFull;

    IEventEmitter public eventEmitter;

    /**
     * @dev Initialization function for proxy contract
     *
     * @param _registry the Registry contract address
     * @param _implementation The economcsImplementation contract address
     */
    // solhint-disable-next-line func-name-mixedcase
    function __EconomicsFactory_init(
        address _registry,
        address _implementation,
        address _fuelToken,
        address _owner
    ) public initializer {
        __Ownable_init(msg.sender);
        __AuthModifiers_init(_registry);
        __EconomicsFactory_init_unchained(_registry, _implementation, _fuelToken, _owner);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __EconomicsFactory_init_unchained(
        address _registry,
        address _implementation,
        address _fuelToken,
        address _owner
    ) internal initializer {
        registry = IRegistry(_registry);
        eventEmitter = IEventEmitter(registry.eventEmitterAddress());
        fuelToken = IERC20(_fuelToken);
        beacon = new UpgradeableBeacon(_implementation, _owner);
    }

    /**
     * @notice Returns the integrator index of a relayer
     * @dev Would revert if integrator isn't configured
     * @param _relayerAddress the relayer address
     * @return _integratorIndex Index of configured integrator
     */
    function configuredIntegratorIndex(address _relayerAddress) external view returns (uint256 _integratorIndex) {
        _integratorIndex = relayerData[_relayerAddress].integratorIndex;
        require(isIntegratorConfigured(_integratorIndex), "EconomicsFactory: integrator not configured");
    }

    /**
     * @notice Returns the Economics contract of an integrator
     * @dev Would revert if integrator isn't configured
     * @param _integratorIndex the integrator index / id
     * @return _economicsAddress Address of economics contract for configured integrator
     */
    function configuredIntegratorEconomics(uint256 _integratorIndex) external view returns (address _economicsAddress) {
        // require(isIntegratorConfigured(_integratorIndex), "EconomicsFactory: integrator not configured");
        _economicsAddress = economicsContracts[_integratorIndex];
    }

    /**
     * @notice Returns the integrator index belonging to a relayer
     * @param _relayerAddress the relayer address
     */
    function relayerToIndex(address _relayerAddress) external view returns (uint32 _integratorIndex) {
        _integratorIndex = relayerData[_relayerAddress].integratorIndex;
    }

    /**
     * Returns the fuel value remaining for an integrator
     * @param _integratorIndex integrator in question
     */
    function returnValueOfFuel(uint256 _integratorIndex) external view returns (uint256 _value) {
        address _economicsAddress = economicsContracts[_integratorIndex];
        _value = IEconomicsImplementation(_economicsAddress).fuelBalanceUsd();
    }

    function isIntegratorConfigured(uint256 _integratorIndex) public view returns (bool _isConfigured) {
        _isConfigured = integratorData[_integratorIndex].isConfigured;
    }

    function isIntegratorEnabled(uint256 _integratorIndex) public view returns (bool _isEnabled) {
        _isEnabled = integratorData[_integratorIndex].isBillingEnabled;
    }

    /**
     * @notice returns dynamic rate of an integrator
     * @param _integratorIndex integrator index in question
     */
    function returnDynamicRatesOfIntegrator(
        uint256 _integratorIndex
    ) external view returns (DynamicRates memory _dynamicRates) {
        _dynamicRates = integratorRates[_integratorIndex];
    }

    /**
     * @notice returns whether or not an integrator is a digital twin
     * @param _relayerAddress the relayer address
     */
    function isIntegratorDigitalTwin(address _relayerAddress) external view returns (bool _isDigitalTwin) {
        uint256 _index = relayerData[_relayerAddress].integratorIndex;
        _isDigitalTwin = isDigitalTwin[_index];
    }

    /**
     * @notice Updates an integrator's dynamic rates
     * @param  _integratorIndex the index of the integrator to update
     * @param  _dynamicRates array containing all the dyanmic rates
     */
    function setDynamicRates(
        uint32 _integratorIndex,
        DynamicRates calldata _dynamicRates
    ) external onlyIntegratorAdmin {
        integratorRates[_integratorIndex] = _dynamicRates;
        emit UpdateDynamicRates(_integratorIndex, _dynamicRates);
    }

    /**
     * @notice Sets an integrator's billing on or off credit
     * @param _integratorIndex  Index of integrator
     * @param _onCredit Credit status
     */
    function setIntegratorOnCredit(uint32 _integratorIndex, bool _onCredit) external onlyIntegratorAdmin {
        integratorData[_integratorIndex].onCredit = _onCredit;
        emit UpdateIntegratorOnCredit(_integratorIndex, _onCredit);
    }

    /**
     * @notice Creates and configures an integrator
     * @dev It sets the the dynamic rates and relayer for an integrator
     *
     * @dev It can only be called by an integrator admin
     *
     * @dev Dynamic rates are used to determine fuel spent by an integrator per specific ticket interraction
     * @param _name Integrator name
     * @param _relayerAddress an integrator relayer address
     * @param _dynamicRates integrator dynamic rates
     */
    function setupIntegrator(
        string calldata _name,
        address _relayerAddress,
        DynamicRates calldata _dynamicRates,
        bool _isDigitalTwin
    ) external onlyIntegratorAdmin returns (address _economicsAddress) {
        uint256 _integratorIndex = integratorCount;
        unchecked {
            integratorCount++;
        }
        require(relayerData[_relayerAddress].integratorIndex == 0, "EconomicsFactory: Relayer already registerd");
        IntegratorData storage integrator = integratorData[_integratorIndex];
        integratorRates[_integratorIndex] = _dynamicRates;
        integrator.index = uint32(_integratorIndex);
        integrator.name = _name;
        if (_isDigitalTwin) isDigitalTwin[_integratorIndex] = true;
        activateIntegrator(integrator.index);
        relayerData[_relayerAddress] = RelayerData(uint32(_integratorIndex));
        _economicsAddress = _newEconomics(_integratorIndex);
        eventEmitter.authorizeByFactory(_economicsAddress);
        emit IntegratorConfigured(_integratorIndex, _name, _relayerAddress, _isDigitalTwin, _dynamicRates);
    }

    /**
     * @notice Acitvates an already existing integrator
     * @dev It's called within setupIntegrator
     *
     * @dev It can only be called by an integrator admin
     *
     * @dev It sets both configuration status and billing status to true
     * @param _integratorIndex index of the integrator in question
     */
    function activateIntegrator(uint32 _integratorIndex) public onlyIntegratorAdmin {
        setConfigurationStatus(_integratorIndex, true);
        setBillingStatus(_integratorIndex, true);
        emit IntegratorActivated(_integratorIndex);
    }

    /**
     * @notice Disables an integrator
     * @dev It can only be called by an integrator admin
     *
     * @dev It sets both configuration status and billing status to false
     * @param _integratorIndex index of the integrator in question
     */
    function disableIntegrator(uint32 _integratorIndex) external onlyIntegratorAdmin {
        setConfigurationStatus(_integratorIndex, false);
        setBillingStatus(_integratorIndex, false);
        emit IntegratorDisabled(_integratorIndex);
    }

    /**
     * @notice Sets the configuration status of an integrator
     * @dev It can only be called by an integrator admin
     * @param _integratorIndex index of integrator in question
     * @param _status configuration status; boolean
     */
    function setConfigurationStatus(uint32 _integratorIndex, bool _status) public onlyIntegratorAdmin {
        integratorData[_integratorIndex].isConfigured = _status;
        emit ConfigurationStatusUpdated(_integratorIndex, _status);
    }

    function setEventEmitter(address _eventEmitter) external onlyIntegratorAdmin {
        eventEmitter = IEventEmitter(_eventEmitter);
        emit EventEmitterSet(_eventEmitter);
    }

    /**
     * @notice Sets the billing status of an integrator
     * @dev It can only be called by an integrator admin
     * @param _integratorIndex index of integrator in question
     * @param _status billing status; boolean
     */
    function setBillingStatus(uint32 _integratorIndex, bool _status) public onlyIntegratorAdmin {
        integratorData[_integratorIndex].isBillingEnabled = _status;
        emit BillingStatusUpdated(_integratorIndex, _status);
    }

    /**
     * @notice Disables billing on an integrator
     * @dev It can only be called by an integrator admin
     * @param _integratorIndex index of the integrator in question
     */
    function disableIntegratorBilling(uint32 _integratorIndex) external onlyIntegratorAdmin {
        setBillingStatus(_integratorIndex, false);
        emit DisableIntegratorBilling(_integratorIndex);
    }

    /**
     * @notice Adds relayer to an already configured integrator
     * @param _relayerAddress address of new relayer
     * @param _integratorIndex index of the integrator
     */
    function addRelayer(address _relayerAddress, uint32 _integratorIndex) external onlyIntegratorAdmin {
        relayerData[_relayerAddress] = RelayerData(_integratorIndex);
        emit RelayerAdded(_relayerAddress, _integratorIndex);
    }

    /**
     * @notice Detaches a relayer from an integrator
     * @dev It can only be called by an integrator admin
     * @param _relayerAddress address to be detached from an integrator
     */
    function removeRelayer(address _relayerAddress) external onlyIntegratorAdmin {
        emit RelayerRemoved(_relayerAddress, relayerData[_relayerAddress].integratorIndex);
        delete relayerData[_relayerAddress];
    }

    /**
     * @notice Internal function to deploy new EconomicsImplementation contract for an integrator
     * @param _integratorIndex  Index of integrator
     * @return _economicsAddress Address of newly deployed Economics contract
     */
    function _newEconomics(uint256 _integratorIndex) internal returns (address _economicsAddress) {
        require(economicsContracts[_integratorIndex] == address(0), "Economics already exists");
        bytes memory _economicsCalldata = abi.encodeWithSignature(
            "__EconomicsImplementationV2_init(address,address)",
            address(registry),
            fuelToken
        );
        _economicsAddress = address(
            new BeaconProxy{ salt: bytes32(uint256(_integratorIndex)) }(address(beacon), _economicsCalldata)
        );
        require(_economicsAddress != address(0x0), "EconomicsFactory: Deployment of economics failed");
        economicsContracts[_integratorIndex] = _economicsAddress;
        economicsToIndex[_economicsAddress] = _integratorIndex;
        emit EconomicsContractDeployed(_economicsAddress, _integratorIndex);
    }

    /**
     * @notice Tops up an integrator
     * @param _integratorIndex index of the integrator
     * @param _sender address of the address that is topping up (transferring the tokens)
     * @param _totalTokens total amount of tokens to be topped up
     * @param _topUpPrice the pricing of the topped up tokens
     * @return _totalFuelUSD total fuel balance in USD after topup
     */
    function topUpIntegrator(
        uint256 _integratorIndex,
        address _sender,
        uint256 _totalTokens,
        uint256 _topUpPrice
    ) external onlyTopUp returns (uint256 _totalFuelUSD) {
        require(isIntegratorConfigured(_integratorIndex), "EconomicsFactory: integrator not configured");
        require(_totalTokens != 0, "EconomicsFactory: zero amount");
        require(_topUpPrice != 0, "EconomicsFactory: incorrect price");
        require(
            fuelToken.allowance(_sender, address(this)) >= _totalTokens,
            "EconomicsFactory: sender lacks allowance"
        );
        fuelToken.transferFrom(_sender, address(this), _totalTokens);
        address _economicsContract = economicsContracts[_integratorIndex];
        require(_economicsContract != address(0), "EconomicsFactory: Invalid Economics address");
        fuelToken.approve(_economicsContract, _totalTokens);
        _totalFuelUSD = IEconomicsImplementation(_economicsContract).topUpEconomics(_totalTokens, _topUpPrice);
        emit IntegratorToppedUp(uint32(_integratorIndex), _economicsContract, _totalTokens, _topUpPrice);
    }

    /**
     * @notice Internal function to perform integrator top up at migration
     * @param _integratorIndex index of the integrator
     * @param _totalTokens total amount of tokens to be topped up
     * @param _topUpPrice the pricing of the topped up tokens
     * @return _totalFuelUSD total fuel balance in USD after topup
     */
    function _topUpIntegratorAtMigration(
        uint256 _integratorIndex,
        uint256 _totalTokens,
        uint256 _topUpPrice
    ) internal returns (uint256 _totalFuelUSD) {
        if (_totalTokens == 0) return _totalFuelUSD;
        require(_topUpPrice != 0, "EconomicsFactory: incorrect price");
        address _economicsContract = economicsContracts[_integratorIndex];
        require(_economicsContract != address(0), "EconomicsFactory: Invalid Economics address");
        fuelToken.approve(_economicsContract, _totalTokens);
        _totalFuelUSD = IEconomicsImplementation(_economicsContract).topUpEconomics(_totalTokens, _topUpPrice);
    }

    /**
     * @notice Enables billing on an integrator
     * @dev It can only be called by an integrator admin
     * @param _integratorIndex index of the integrator in question
     */
    function enableIntegratorBilling(uint32 _integratorIndex) external onlyIntegratorAdmin {
        setBillingStatus(_integratorIndex, true);
        emit EnableIntegratorBilling(_integratorIndex);
    }

    /**
     * @notice Sets the address for the fuel token; typically $OPN
     * @dev It can only be called by the contract owner
     * @param _fuelToken contract address of fuel token
     */
    function setFuelToken(address _fuelToken) external onlyOwner {
        emit UpdateFuelToken(address(fuelToken), _fuelToken);
        fuelToken = IERC20(_fuelToken);
    }

    /**
     * @notice Updates the protocol rates
     * @param  _protocolRates array containing all the dyanmic rates
     */
    function setProtocolRates(DynamicRates calldata _protocolRates) public onlyOwner {
        protocolRates = _protocolRates;
        emit UpdateProtocolRates(_protocolRates);
    }

    /**
     * @notice Updates integrator name
     * @param _integratorIndex Index of integrator
     * @param _name Name of integrator
     */
    function setIntegratorName(uint256 _integratorIndex, string calldata _name) external onlyIntegratorAdmin {
        integratorData[_integratorIndex].name = _name;
        emit IntegratorNameSet(_integratorIndex, _name);
    }

    function _attachRelayer(uint256 _integratorId, address _relayerAddress) internal {
        require(relayerData[_relayerAddress].integratorIndex == 0, "EconomicsFactory: Relayer already registerd");
        relayerData[_relayerAddress] = RelayerData(uint32(_integratorId));
    }

    /**
     * @notice Withdraws an asset on this contract to a given address
     * @dev This becomes usefull when migrating an Economics contract to another
     *
     * @dev It can only be called by the contract owner
     * @param _asset contract address of a particular asset
     * @param _to address the asset is sent to
     * @param _amount amount of the asset to be sent
     */
    function emergencyWithdraw(address _asset, address _to, uint256 _amount) external onlyOwner {
        IERC20(_asset).transfer(_to, _amount);
    }

    function initialize() external onlyOwner {
        wasUpgradeSuccessFull = true;
    }

    /**
     * @notice An internal function to authorize a contract upgrade
     * @dev The function is a requirement for OpenZeppelin's UUPS upgradeable contracts
     *
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
