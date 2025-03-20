// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IAuth } from "./interfaces/IAuth.sol";
/**
 * @title Auth Contract
 * @author Open Ticketing Ecosystem
 * @notice Contract responsible for protocol wide access control
 */
contract Auth is IAuth, AccessControlUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    bytes32 private constant _MASTER_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 private constant _GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 private constant _INTEGRATOR_ADMIN_ROLE = keccak256("INTEGRATOR_ADMIN_ROLE");
    bytes32 private constant _EVENT_FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 private constant _EVENT_ROLE = keccak256("EVENT_ROLE");
    bytes32 private constant _FUEL_DISTRIBUTOR_ROLE = keccak256("FUEL_DISTRIBUTOR_ROLE");
    bytes32 private constant _RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 private constant _TOP_UP_ROLE = keccak256("TOP_UP_ROLE");
    bytes32 private constant _CUSTODIAL_TOP_UP_ROLE = keccak256("CUSTODIAL_TOP_UP_ROLE");
    bytes32 private constant _PRICE_ORACLE_ROLE = keccak256("PRICE_ORACLE_ROLE");
    bytes32 private constant _ROUTER_REGISTRY_ROLE = keccak256("ROUTER_REGISTRY_ROLE");
    bytes32 private constant _ECONOMICS_FACTORY_ROLE = keccak256("ECONOMICS_FACTORY_ROLE");
    bytes32 private constant _FUEL_ROUTER_ROLE = keccak256("FUEL_ROUTER_ROLE");
    bytes32 private constant _PROTOCOL_DAO_ROLE = keccak256("PROTOCOL_DAO_ROLE");
    bytes32 private constant _EFM_ROLE_INTEGRATOR = keccak256("EFM_INTEGRATOR_ROLE");
    bytes32 private constant _ECONOMICS_INTEGRATOR_ROLE = keccak256("ECONOMICS_INTEGRATOR_ROLE");
    bytes32 private constant _STAKING_BALANCE_ORACLE_ROLE = keccak256("STAKING_BALANCE_ORACLE_ROLE");
    bytes32 private constant _ACTIONS_PROCESSOR_ROLE = keccak256("ACTIONS_PROCESSOR_ROLE");

    mapping(address => uint256) public integratorAdminToIndex;

    bool public areRolesSetup;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initialization function for proxy contract
     * @param _owner owner contract address
     * @param _eventFactory EventFactory contract address
     * @param _topUp TopUp contract address
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Auth_init(address _owner, address _eventFactory, address _topUp) external initializer {
        __Ownable_init(_owner);
        __AccessControl_init();
        __Auth_init_unchained(_owner, _eventFactory, _topUp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Auth_init_unchained(address _owner, address _eventFactory, address _topUp) internal initializer {
        _grantRole(_MASTER_ROLE, _owner);
        _grantRole(_EVENT_FACTORY_ROLE, _eventFactory);
        _grantRole(_TOP_UP_ROLE, _topUp);
        _setRoleAdmin(_RELAYER_ROLE, _INTEGRATOR_ADMIN_ROLE);
        _setRoleAdmin(_EVENT_ROLE, _EVENT_FACTORY_ROLE);
    }

    /**
     * @notice Initializer function called on upgrade
     * @param _owner multisig address
     * @param _routerRegistry router registry contract address
     * @param _economicsFactory  economics factory contract address
     */
    function setRoleAdmins(address _owner, address _routerRegistry, address _economicsFactory) external onlyOwner {
        require(areRolesSetup == false, "Auth:ROLES_INITIALIZED");
        _grantRole(_PROTOCOL_DAO_ROLE, _owner);
        _grantRole(_EFM_ROLE_INTEGRATOR, _owner);
        _grantRole(_ECONOMICS_INTEGRATOR_ROLE, _owner);
        _grantRole(_ROUTER_REGISTRY_ROLE, _routerRegistry);
        _grantRole(_FUEL_ROUTER_ROLE, _owner);
        _grantRole(_ECONOMICS_FACTORY_ROLE, _economicsFactory);

        _setRoleAdmin(_EFM_ROLE_INTEGRATOR, _INTEGRATOR_ADMIN_ROLE);
        _setRoleAdmin(_ECONOMICS_INTEGRATOR_ROLE, _INTEGRATOR_ADMIN_ROLE);
        _setRoleAdmin(_ECONOMICS_FACTORY_ROLE, _INTEGRATOR_ADMIN_ROLE);
        _setRoleAdmin(_ROUTER_REGISTRY_ROLE, _INTEGRATOR_ADMIN_ROLE);
        _setRoleAdmin(_FUEL_ROUTER_ROLE, _INTEGRATOR_ADMIN_ROLE);
        // _setRoleAdmin(_ACTIONS_PROCESSOR_ROLE, _INTEGRATOR_ADMIN_ROLE);
        areRolesSetup = true;
    }

    /**
     * @dev Filters out accounts without a specific role in question
     * @param role Role being checked for
     * @param sender Account under scrutiny
     */
    modifier senderHasRole(bytes32 role, address sender) {
        _checkRole(role, sender);
        _;
    }

    function senderProtected(bytes32 _roleId) external view onlyRole(_roleId) {}

    /**
     * @notice Checks for a _GOVERNANCE_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasGovernanceRole(address _sender) external view senderHasRole(_GOVERNANCE_ROLE, _sender) {}

    /**
     * @notice Checks for an _INTEGRATOR_ADMIN_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasIntegratorAdminRole(address _sender) external view senderHasRole(_INTEGRATOR_ADMIN_ROLE, _sender) {}

    /**
     * @notice Checks for a _EVENT_FACTORY_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasEventFactoryRole(address _sender) external view senderHasRole(_EVENT_FACTORY_ROLE, _sender) {}

    /**
     * @notice Checks for a _ECONOMICS_FACTORY_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasEconomicsFactoryRole(address _sender) external view senderHasRole(_ECONOMICS_FACTORY_ROLE, _sender) {}

    /**
     * @notice Checks for a _RELAYER_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasRelayerRole(address _sender) external view senderHasRole(_RELAYER_ROLE, _sender) {}

    /**
     * @notice Checks for an _EVENT_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasEventRole(address _sender) external view senderHasRole(_EVENT_ROLE, _sender) {}

    /**
     * @notice Checks for a _TOP_UP_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasTopUpRole(address _sender) external view senderHasRole(_TOP_UP_ROLE, _sender) {}

    /**
     * @notice Checks for a _CUSTODIAL_TOP_UP_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasCustodialTopUpRole(address _sender) external view senderHasRole(_CUSTODIAL_TOP_UP_ROLE, _sender) {}

    /**
     * @notice Checks for a _PRICE_ORACLE_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasPriceOracleRole(address _sender) external view senderHasRole(_PRICE_ORACLE_ROLE, _sender) {}

    /**
     * @notice Checks for a _STAKING_BALANCE_ORACLE_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasStakingBalanceOracleRole(
        address _sender
    ) external view senderHasRole(_STAKING_BALANCE_ORACLE_ROLE, _sender) {}

    /**
     * @notice Checks for a _ACTIONS_PROCESSOR_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasActionsProcessorRole(address _sender) external view senderHasRole(_ACTIONS_PROCESSOR_ROLE, _sender) {}

    /**
     * @notice Checks for a _FUEL_ROUTER_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasFuelRouterRole(address _sender) external view senderHasRole(_FUEL_ROUTER_ROLE, _sender) {}

    /**
     * @notice Checks for a _ROUTER_REGISTRY_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasRouterRegistryRole(address _sender) external view senderHasRole(_ROUTER_REGISTRY_ROLE, _sender) {}

    function hasProtocolDAORole(address _sender) external view senderHasRole(_PROTOCOL_DAO_ROLE, _sender) {}

    /**
     * @notice Grants an address an _EVENT_ROLE
     * @dev Only Event contracts are granted an _EVENT_ROLE
     * @param _event Event contract address
     */
    function grantEventRole(address _event) public senderHasRole(_EVENT_FACTORY_ROLE, msg.sender) {
        grantRole(_EVENT_ROLE, _event);
    }

    /**
     * @notice Grants an address an _ACTIONS_PROCESSOR_ROLE
     * @dev Only Event contracts are granted an _ACTIONS_PROCESSOR_ROLE
     * @param _actionsProcessor ActionsProcessor contract address
     */
    function grantActionsProcessorRole(
        address _actionsProcessor
    ) public senderHasRole(_INTEGRATOR_ADMIN_ROLE, msg.sender) {
        _grantRole(_ACTIONS_PROCESSOR_ROLE, _actionsProcessor);
    }

    function addIntegratorAdminToIndex(
        address _integratorAdmin,
        uint256 _integratorIndex
    ) external onlyRole(_MASTER_ROLE) {
        require(integratorAdminToIndex[_integratorAdmin] == 0, "Auth: integrator admin already exists");
        integratorAdminToIndex[_integratorAdmin] = _integratorIndex;
    }

    function removeIntegratorAdmin(address _integratorAdmin) external onlyRole(_MASTER_ROLE) {
        delete integratorAdminToIndex[_integratorAdmin];
    }

    function hasEconomicsConfigurationRole(
        address _sender,
        uint256 _integratorIndex
    ) external view senderHasRole(_EFM_ROLE_INTEGRATOR, _sender) {
        require(
            integratorAdminToIndex[_sender] == _integratorIndex,
            "Auth: sender lacks configuration role for this integrator"
        );
    }

    function hasEventFinancingConfigurationRole(
        address _sender,
        uint256 _integratorIndex
    ) external view senderHasRole(_ECONOMICS_INTEGRATOR_ROLE, _sender) {
        require(integratorAdminToIndex[_sender] == _integratorIndex, "Auth: sender lacks role for integrator");
    }

    /**
     * @notice  A internal function to authorize a contract upgrade
     * @dev The function is a requirement for Openzeppelin's UUPS upgradeable contracts
     *
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
