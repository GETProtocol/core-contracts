// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title AuthModifiers Contract
 * @author Open Ticketing Ecosystem
 * @notice This contract provides access control modifiers to the Auth contract
 * @dev It's implemented as an abstract contract
 */

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IRegistry } from "../interfaces/IRegistry.sol";

abstract contract AuthModifiers is Initializable {
    IRegistry private registry;

    // solhint-disable-next-line func-name-mixedcase
    function __AuthModifiers_init_unchained(address _registry) internal initializer {
        registry = IRegistry(_registry);
    }

    /**
     * @dev initialization function for proxy contract
     * @param _registry the Registry contract address
     */

    // solhint-disable-next-line func-name-mixedcase
    function __AuthModifiers_init(address _registry) public initializer {
        __AuthModifiers_init_unchained(_registry);
    }

    /**
     * @dev Throws if called by any account other than an Open Ticketing Ecosystem Relayer admin account.
     */
    modifier onlyIntegratorAdmin() {
        registry.auth().hasIntegratorAdminRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any account other than an Open Ticketing Ecosystem Relayer account.
     */
    modifier onlyRelayer() {
        registry.auth().hasRelayerRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than an Open Ticketing Ecosystem Factory contract.
     */
    modifier onlyEventFactory() {
        registry.auth().hasEventFactoryRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract different from an instance of a Open Ticketing Ecosystem Event Contract
     */
    modifier onlyEvent() {
        registry.auth().hasEventRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the Open Ticketing Ecosystem TopUp Contract.
     */
    modifier onlyTopUp() {
        registry.auth().hasTopUpRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any account other than the Open Ticketing Ecosystem EOA(S) designated for TopUps.
     */
    modifier onlyCustodialTopUp() {
        registry.auth().hasCustodialTopUpRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the PriceOracle update EOA.
     */
    modifier onlyPriceOracle() {
        registry.auth().hasPriceOracleRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the StakingBalanceOracle update EOA.
     */
    modifier onlyStakingBalanceOracle() {
        registry.auth().hasStakingBalanceOracleRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the router registry contract
     */
    modifier onlyRouterRegistry() {
        registry.auth().hasRouterRegistryRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the fuel router contract
     */
    modifier onlyFuelRouter() {
        registry.auth().hasFuelRouterRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the actions processor contract
     */
    modifier onlyActionsProcessor() {
        registry.auth().hasActionsProcessorRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the economics factory contract
     */
    modifier onlyEconomicsFactory() {
        registry.auth().hasEconomicsFactoryRole(msg.sender);
        _;
    }

    modifier onlyProtocolDAO() {
        registry.auth().hasProtocolDAORole(msg.sender);
        _;
    }

    modifier onlyIntegratorEconomicsConfiguration(uint256 _integratorIndex) {
        registry.auth().hasEconomicsConfigurationRole(msg.sender, _integratorIndex);
        _;
    }

    modifier onlyIntegratorEventFinancingConfiguration(uint256 _integratorIndex) {
        registry.auth().hasEventFinancingConfigurationRole(msg.sender, _integratorIndex);
        _;
    }

    modifier hasEventRole(address _address) {
        registry.auth().hasEventRole(_address);
        _;
    }
}
