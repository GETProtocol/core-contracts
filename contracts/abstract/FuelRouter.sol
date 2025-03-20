// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title FuelRouter Contract
 * @author Open Ticketing Ecosystem
 * @notice Abstract contract responsible for fuel routing
 * @dev Intentionally deployed as non-proxy contracts
 */

import { AuthModifiers } from "./AuthModifiers.sol";
import { IFuelRouter } from "../interfaces/IFuelRouter.sol";
import { IEconomicsImplementation } from "../interfaces/IEconomicsImplementation.sol";
import { IEconomicsImplementation } from "../interfaces/IEconomicsImplementation.sol";
import { IEventImplementation } from "../interfaces/IEventImplementation.sol";
import { IEconomicsFactory } from "../interfaces/IEconomicsFactory.sol";
import { IRegistry, IAuth } from "../interfaces/IRegistry.sol";

abstract contract FuelRouter is IFuelRouter, AuthModifiers {
    IAuth public auth;
    IRegistry public registry;
    address public economics;
    RouterType public routerType;
    uint256 public mintBaseRate; // pricing

    constructor(uint256 _baseRate, address _registry, uint256 _integratorId) {
        __AuthModifiers_init(_registry);
        registry = IRegistry(_registry);
        auth = IAuth(registry.auth());
        mintBaseRate = _baseRate;

        IEconomicsFactory economicsFactory_ = registry.economicsFactory();

        // Product fee (3%) from WL to International (for product)
        // Protocol fee ($0.02) from WL to Protocol (for protocol)
        // Both fees are charged from the economics contracts of the integrators
        economics = address(economicsFactory_.configuredIntegratorEconomics(_integratorId));
    }

    /**
     * @dev Throws if called by any contract different from an instance of a Open Ticketing Ecosystem Event Contract
     */
    modifier onlyEventImplementation() {
        auth.hasEventRole(msg.sender);
        _;
    }

    /**
     * @notice Returns whether or not a router is for a whitelabel
     */
    function isRouterWhitelabelRouter() external view returns (bool isWhitelabelRouter_) {
        if (routerType == RouterType.NONE) {
            revert("FuelRouter: Invalid routertype");
        } else if (routerType == RouterType.DIGITAL_TWIN_ROUTER) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice Gets primary sale fuel usage, defaults to zero.
     */
    function routeFuelForPrimarySale(
        IEventImplementation.TicketAction[] calldata
    ) external virtual onlyEventImplementation returns (uint256, uint256, uint256, uint256) {
        return (0, 0, 0, 0);
    }

    /**
     * @notice Gets secondary sale fuel usage, defaults to zero.
     */
    function routeFuelForSecondarySale(
        IEventImplementation.TicketAction[] calldata
    ) external virtual onlyEventImplementation returns (uint256, uint256, uint256, uint256) {
        return (0, 0, 0, 0);
    }

    /**
     * @notice Sets mint base rate for Router
     * @param _baseRate  value for mint base rate
     */
    function _setMintBaseRate(uint256 _baseRate) internal {
        mintBaseRate = _baseRate;
    }

    /**
     * @notice Calculates total base fee for a number of ticket actions
     * @param _amountActions Number of ticket actions
     * @return _totalFuelProtocolValue Cummulative fuel value
     */
    function _calculateBaseFee(uint256 _amountActions) internal view returns (uint256 _totalFuelProtocolValue) {
        unchecked {
            _totalFuelProtocolValue = _amountActions * mintBaseRate * 1e15;
        }
    }

    /**
     * @notice Returns fuel to be routed from EconomicsImplementation contract
     * @param _economicsFrom address of the economics contract to calculate tokens to be routed from
     * @param _fuelAmountUSD  amount of fuel in USD to be routed
     * @param _feeType fee type to be routed
     * @return _fuelTokenAmount amount of fuel tokens routed
     */
    function _fuelToBeRouted(
        address _economicsFrom,
        uint256 _fuelAmountUSD,
        FeeType _feeType
    ) internal returns (uint256 _fuelTokenAmount) {
        if (_fuelAmountUSD == 0) {
            return 0;
        } else {
            _fuelTokenAmount = IEconomicsImplementation(_economicsFrom).getFuelFromTicks(_fuelAmountUSD, _feeType);
        }
    }
}
