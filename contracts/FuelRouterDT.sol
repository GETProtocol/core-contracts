// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// solhint-disable-next-line max-line-length
import { FuelRouter, IEventImplementation, IEconomicsFactory, IEconomicsImplementation } from "./abstract/FuelRouter.sol";
import { IFuelRouterDT } from "./interfaces/IFuelRouterDT.sol";

/**
 * @title FuelRouterDT Contract
 * @author Open Ticketing Ecosystem
 * @notice Fuel Router contract for digital tiwn integrators
 * @dev In production, fuel strictly refers to $OPN
 *
 * @dev Fuel is denominated in 18 decimals
 */
contract FuelRouterDT is IFuelRouterDT, FuelRouter {
    uint256 public immutable integratorId;
    DynamicRate public primarySaleRateProduct;

    constructor(
        address _registry,
        uint256 _baseRate,
        uint256 _integratorId
    ) FuelRouter(_baseRate, _registry, _integratorId) {
        integratorId = _integratorId;

        IEconomicsFactory _economicsFactory = IEconomicsFactory(registry.economicsFactory());

        IEconomicsFactory.DynamicRates memory _dynamicRates = _economicsFactory.returnDynamicRatesOfIntegrator(
            _integratorId
        );

        // rate configuration primary market fee
        primarySaleRateProduct.minFeeValue = _dynamicRates.minFeePrimary;
        primarySaleRateProduct.maxFeeValue = _dynamicRates.maxFeePrimary;
        primarySaleRateProduct.rateDynamic = _dynamicRates.primaryRate;

        // Set the mint rate to be equal to the min fee primary (100% paid to DAO).
        _setMintBaseRate(_dynamicRates.minFeePrimary);

        routerType = RouterType.DIGITAL_TWIN_ROUTER;
    }

    /**
     * @notice Sets upper and lower boundary for primary sale rates
     * @param _minFeeValue minimum amount of ticket fee
     * @param _maxFeeValue maximum amount of ticket fee
     * @param _rateDynamic percetantage fee charged over ticket value
     */
    function setPrimaryRateProduct(
        uint64 _minFeeValue,
        uint64 _maxFeeValue,
        uint64 _rateDynamic
    ) external onlyIntegratorAdmin {
        primarySaleRateProduct.minFeeValue = _minFeeValue;
        primarySaleRateProduct.maxFeeValue = _maxFeeValue;
        primarySaleRateProduct.rateDynamic = _rateDynamic;
        emit PrimaryRateProductChanged(_minFeeValue, _maxFeeValue, _rateDynamic);
    }

    // ROUTING FUNCTIONS

    /**
     * @notice function called by the event implementaton contract to route a fuel demand of a primary sale
     * @param _ticketActions TicketAction struct with primary market nft sale information
     * @return _totalFuelTokens total fuel tokens routed (protocol fuel inclusive)
     * @return _protocolFuelTokens protocol fuel tokens routed
     * @return _totalFuelUSD amount of fuel routed in USD
     * @return _protocolFuelUSD amount of fuel routed in USD for protocol
     */
    function routeFuelForPrimarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    )
        external
        override(FuelRouter)
        onlyActionsProcessor
        returns (uint256 _totalFuelTokens, uint256 _protocolFuelTokens, uint256 _totalFuelUSD, uint256 _protocolFuelUSD)
    {
        bool isEnabled = registry.economicsFactory().isIntegratorEnabled(integratorId);
        if (!isEnabled) return (0, 0, 0, 0);

        (_totalFuelTokens, _protocolFuelTokens, _totalFuelUSD, _protocolFuelUSD) = _routePrimarySale(_ticketActions);
    }

    function setMintBaseRate(uint256 _baseRate) external onlyProtocolDAO {
        _setMintBaseRate(_baseRate);
    }

    /**
     * @notice Routes fuel for a digital twin primary sale
     * @param _ticketActions  Array of ticket actions structs
     * @return _totalFuel total fuel of product fee including protocol fee
     * @return _protocolFuel amount of tokens routed for prototcol fee
     * @return _totalFee amount of fuel in USD
     * @return _protocolFee amount of fuel in USD for protocol
     */
    function _routePrimarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) internal returns (uint256 _totalFuel, uint256 _protocolFuel, uint256 _totalFee, uint256 _protocolFee) {
        _totalFee = _calculateProductFeePrimary(_ticketActions);
        _protocolFee = _calculateBaseFee(_ticketActions.length);
        uint256 _treasuryFee;
        if (_protocolFee >= _totalFee) {
            _protocolFee = _totalFee;
        } else {
            _treasuryFee = _totalFee - _protocolFee;
        }

        uint256 _treasuryFuel = _fuelToBeRouted(economics, _treasuryFee, FeeType.TREASURY);
        _protocolFuel = _fuelToBeRouted(economics, _protocolFee, FeeType.PROTOCOL);

        _totalFuel = _treasuryFuel + _protocolFuel;

        IEconomicsImplementation(economics).transferFuelToCollector(_totalFuel, _protocolFuel, _treasuryFuel, 0);

        emit RouteRequestFilledDTPrimarySale(msg.sender, economics, _totalFuel, _totalFee, _ticketActions.length);

        return (_totalFuel, _protocolFuel, _totalFee, _protocolFee);
    }

    /**
     * @notice Calculates the fuel cost for a primary sale for the product
     * @dev Charges dynamic fees based on the ticket price (and the configured min and max prices)
     * @param _ticketActions Array of ticket actions structs
     * @param _fuelValue total cost for the product portion of the primary sale in USD
     */
    function _calculateProductFeePrimary(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) internal view returns (uint256 _fuelValue) {
        DynamicRate memory _primaryRateProduct = primarySaleRateProduct;

        uint256 _minFeeValue = uint256(_primaryRateProduct.minFeeValue) * 1e15;
        uint256 _maxFeeValue = uint256(_primaryRateProduct.maxFeeValue) * 1e15;
        uint256 _rate = uint256(_primaryRateProduct.rateDynamic);

        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _feeUsdValue;

            unchecked {
                _feeUsdValue = uint256(_ticketActions[i].basePrice) * _rate * 1e9;
                if (_feeUsdValue <= _minFeeValue) {
                    _fuelValue += _minFeeValue;
                } else if (_maxFeeValue == 0 || _feeUsdValue < _maxFeeValue) {
                    _fuelValue += _feeUsdValue;
                } else {
                    _fuelValue += _maxFeeValue;
                }
            }
        }
    }

    function returnPrimaryRateProduct() external view returns (DynamicRate memory) {
        return primarySaleRateProduct;
    }
}
