// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// solhint-disable-next-line max-line-length
import { FuelRouter, IEventImplementation, IEconomicsFactory, IEconomicsImplementation } from "./abstract/FuelRouter.sol";
import { IFuelRouterWL } from "./interfaces/IFuelRouterWL.sol";

/**
 * @title FuelRouterDT Contract
 * @author Open Ticketing Ecosystem
 * @notice Fuel Router contract for whitelabel integrators
 * @dev In production, fuel strictly refers to $OPN
 *
 * @dev Fuel is denominated in 18 decimals
 */
contract FuelRouterWL is IFuelRouterWL, FuelRouter {
    uint256 public integratorId;
    DynamicRate public primarySaleRateProduct;
    DynamicRate public secondarySaleRateProduct;
    uint256 public treasuryRate;

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

        secondarySaleRateProduct.minFeeValue = _dynamicRates.minFeeSecondary;
        secondarySaleRateProduct.maxFeeValue = _dynamicRates.maxFeeSecondary;
        secondarySaleRateProduct.rateDynamic = _dynamicRates.secondaryRate;

        routerType = RouterType.WHITE_LABEL_ROUTER;
        treasuryRate = 80;
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

    /**
     * @notice Sets upper and lower boundary for secondary sale rates
     * @param _minFeeValue minimum amount of ticket fee
     * @param _maxFeeValue maximum amount of ticket fee
     * @param _rateDynamic percetantage fee charged over ticket value
     */
    function setSecondaryRateProduct(
        uint64 _minFeeValue,
        uint64 _maxFeeValue,
        uint64 _rateDynamic
    ) external onlyIntegratorAdmin {
        secondarySaleRateProduct.minFeeValue = _minFeeValue;
        secondarySaleRateProduct.maxFeeValue = _maxFeeValue;
        secondarySaleRateProduct.rateDynamic = _rateDynamic;
        emit SecondaryRateProductChanged(_minFeeValue, _maxFeeValue, _rateDynamic);
    }

    // ROUTING FUNCTIONS

    /**
     * This is a 'basic' whitelabel fuel router. Routers are generally immutable or otherwise maximally trustless.
     * They are used because 'you know what you get'. We do want to emulate these benefits.
     *
     * In AMM swapping routers play a role when a swap involves one of more temporary 'hop' assets,
     * meaning that routers hold, intra tx. This is also the case with primarySale.
     * If a WL sells a ticket international charges 3%.  This fuel will flow from the
     * WL-economics address to the the product (dripcollectors of stakers and treasury fuel) contract likely.
     *
     * However in this same transaction the integrator also pays a fee to the protocol.
     * Fee is settled by same router. The router acts as a standardized clearinghouse for agreed upon transcations.
     * Approvals to routers should not bear any risks and therefor we need to make sure that routers
     * are minimally configurable (or prefrably not at all).
     *
     * In the future a fuelrouter could also be confugured to spread for example the proceeds of a secondary market
     * ticket resale to the artist, agent, protocol and so forth.
     *
     * Integrators should only approve routers they trust. Since by approving
     * them they also  aproove them to touch their fuel.
     *
     */

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

    /**
     * @notice function called by the event implementaton contract to route a fuel demand of a secondary sale
     * @param _ticketActions TicketAction struct with secondary market nft sale information
     * @return _totalFuelTokens total fuel tokens routed
     * @return _protocolFuelTokens protocol fuel tokens routed
     * @return _totalFuelUSD amount of fuel routed in USD
     * @return _protocolFuelUSD amount of fuel routed in USD for protocol
     */
    function routeFuelForSecondarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    )
        external
        override(FuelRouter)
        onlyActionsProcessor
        returns (uint256 _totalFuelTokens, uint256 _protocolFuelTokens, uint256 _totalFuelUSD, uint256 _protocolFuelUSD)
    {
        bool isEnabled = registry.economicsFactory().isIntegratorEnabled(integratorId);
        if (!isEnabled) return (0, 0, 0, 0);

        (_totalFuelTokens, _protocolFuelTokens, _totalFuelUSD, _protocolFuelUSD) = _routeSecondarySale(_ticketActions);
    }

    function setMintBaseRate(uint256 _baseRate) external onlyProtocolDAO {
        _setMintBaseRate(_baseRate);
    }

    /**
     * @notice Routes fuel for a whitelabel primary sale
     * @param _ticketActions  Array of ticket actions structs
     * @return _totalFuel total fuel deducted, taken as the product fee
     * @return _protocolFuel amount of tokens routed for protocol fee
     * @return _totalFee amount of fuel in USD
     * @return _protocolFee amount of fuel in USD for protocol
     */
    function _routePrimarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) internal returns (uint256 _totalFuel, uint256 _protocolFuel, uint256 _totalFee, uint256 _protocolFee) {
        _totalFee = _calculateProductFeePrimary(_ticketActions);
        _protocolFee = _calculateBaseFee(_ticketActions.length);
        uint256 _productFee;
        if (_protocolFee >= _totalFee) {
            _protocolFee = _totalFee;
        } else {
            _productFee = _totalFee - _protocolFee;
        }

        uint256 _treasuryFee = (_productFee * treasuryRate) / 100;
        uint256 _stakersFee = _productFee - _treasuryFee;

        uint256 _treasuryFuel = _fuelToBeRouted(economics, _treasuryFee, FeeType.TREASURY);
        uint256 _stakersFuel = _fuelToBeRouted(economics, _stakersFee, FeeType.STAKERS);
        _protocolFuel = _fuelToBeRouted(economics, _protocolFee, FeeType.PROTOCOL);

        _totalFuel = _treasuryFuel + _stakersFuel + _protocolFuel;

        IEconomicsImplementation(economics).transferFuelToCollector(
            _totalFuel, // Total fuel to be routed, protocolFuel already taken from productFee
            _protocolFuel,
            _treasuryFuel,
            _stakersFuel
        );

        emit RouteRequestFilledWLPrimarySale(msg.sender, economics, _totalFuel, _totalFee, _ticketActions.length);

        return (_totalFuel, _protocolFuel, _totalFee, _protocolFee);
    }

    /**
     * @notice Routes fuel for a whitelabel secondary sale
     * @param _ticketActions  Array of ticket actions structs
     * @return _totalFuel total fuel taken as product fee
     * @return amount of tokens routed for protocol fee
     * @return _totalFee amount of fuel in USD
     * @return _protocolFee amount of fuel in USD for protocol
     */
    function _routeSecondarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) internal returns (uint256 _totalFuel, uint256, uint256 _totalFee, uint256) {
        // Calculate the product fee as the total fee. The protocol fee is deducted from the product fee.
        _totalFee = _calculateProductFeeSecondary(_ticketActions);

        uint256 _treasuryFee = (_totalFee * treasuryRate) / 100;
        uint256 _stakersFee = _totalFee - _treasuryFee;

        uint256 _treasuryFuel = _fuelToBeRouted(economics, _treasuryFee, FeeType.TREASURY);
        uint256 _stakersFuel = _fuelToBeRouted(economics, _stakersFee, FeeType.STAKERS);

        _totalFuel = _treasuryFuel + _stakersFuel;

        IEconomicsImplementation(economics).transferFuelToCollector(_totalFuel, 0, _treasuryFuel, _stakersFuel);

        emit RouteRequestFilledWLSecondarySale(msg.sender, economics, _totalFuel, _totalFee, _ticketActions.length);

        return (_totalFuel, 0, _totalFee, 0);
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

    /**
     * @notice Calculate the fuel cost for a secondary sale for the product
     * @dev Charges dynamic fees based on the ticket price (and the configured min and max prices)
     * @param _ticketActions Array of ticket actions structs
     * @return _fuelValue total cost for the product portion of the secondary sale in USD
     */
    function _calculateProductFeeSecondary(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) internal view returns (uint256 _fuelValue) {
        DynamicRate memory _secondaryRateProduct = secondarySaleRateProduct;

        uint256 _minFeeValue = uint256(_secondaryRateProduct.minFeeValue) * 1e15;
        uint256 _maxFeeValue = uint256(_secondaryRateProduct.maxFeeValue) * 1e15;
        uint256 _rate = uint256(_secondaryRateProduct.rateDynamic);

        _fuelValue = 0;

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

    function settreasuryRate(uint256 treasuryRate_) external onlyIntegratorAdmin {
        require(treasuryRate_ <= 100, "FuelRouterWL: Invalid stake rate");
        treasuryRate = treasuryRate_;
        emit TreasuryRateUpdated(treasuryRate_);
    }

    // View functions

    function returnPrimaryRateProduct() external view returns (DynamicRate memory) {
        return primarySaleRateProduct;
    }

    function returnSecondaryRateProduct() external view returns (DynamicRate memory) {
        return secondarySaleRateProduct;
    }
}
