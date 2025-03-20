// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IEventImplementation } from "../../interfaces/IEventImplementation.sol";

interface IEconomics {
    // Data structure containing all the different rates for a particular relayer.
    //   100% (1) 1_000_000,
    //   10% (0.1) = 100_000,
    //   1% (0.01) = 10_000,
    //   0.1% (0.001) = 1_000,
    //   0.01% (0.0001) = 100,
    //   0.001% (0,00001) = 10,
    //   0.0001% = (0.000001) = 1
    // All scaled by 1_000_000.
    //
    // USD values (e.g. minFee, maxFee) are scaled by 1_000 (tenth of a cent).
    struct DynamicRates {
        uint24 minFeePrimary;
        uint24 maxFeePrimary;
        uint24 primaryRate;
        uint24 minFeeSecondary;
        uint24 maxFeeSecondary;
        uint24 secondaryRate;
        uint24 salesTaxRate;
    }

    // Largely unnecesary to define separately but helps avoid stack too deep errors within reserved fuel calculations.
    struct Rate {
        uint24 minFee;
        uint24 maxFee;
        uint24 rate;
    }

    struct IntegratorData {
        uint32 index;
        uint32 activeTicketCount;
        bool isBillingEnabled;
        bool isConfigured;
        uint256 price;
        uint256 availableFuel;
        uint256 reservedFuel;
        uint256 reservedFuelProtocol;
        string name;
        bool onCredit;
    }

    struct RelayerData {
        uint32 integratorIndex;
    }

    struct SpentFuel {
        uint256 total;
        uint256 protocol;
        uint32 ticketCount;
    }

    event IntegratorToppedUp(
        uint32 indexed integratorIndex,
        uint256 indexed total,
        uint256 price,
        uint256 indexed newAveragePrice,
        uint256 salesTax
    );
    event FuelReservedPrimary(uint32 integratorIndex, uint32 ticketCount, uint256 fuel, uint256 fuelProtocol);
    event FuelReservedSecondary(uint32 integratorIndex, uint32 ticketCount, uint256 fuel, uint256 fuelProtocol);
    event BasicTaxCharged(uint32 integratorIndex, uint32 actionCount, uint256 fuel, uint256 fuelProtocol);
    event TicketFuelEmptied(uint32 integratorIndex, uint32 ticketCount, uint256 fuel, uint256 fuelProtocol);
    event SalesTaxFuelCollected(address salesTaxFuelDesintation, uint256 salesTaxFuel);
    event AccountBalanceCorrected(
        uint32 integratorIndex,
        uint256 oldAvailableFuel,
        uint256 newAvailableFuel,
        uint256 oldReservedBalance,
        uint256 newReservedBalance,
        uint256 oldReservedBalanceProtocol,
        uint256 newReservedBalanceProtocol
    );
    event UpdateBasicTaxRate(uint24 old, uint24 updated);
    event UpdateFuelToken(address old, address updated);
    event UpdateSpentFuel(SpentFuel spentFuel);
    event UpdateSpentFuelOnCredit(uint256 spentFuelOnCredit);
    event UpdateDynamicRates(uint32 integratorIndex, DynamicRates dynamicRates);
    event UpdateProtocolRates(DynamicRates protocolRates);
    event UpdateSalesTaxFuelDestination(address salesTaxFuelDestination);
    event IntegratorConfigured(uint32 integratorIndex, string name, address relayerAddress, DynamicRates dynamicRates);
    event IntegratorActivated(uint32 integratorIndex);
    event IntegratorDisabled(uint32 integratorIndex);
    event RelayerAdded(address relayerAddress, uint32 integratorIndex);
    event RelayerRemoved(address relayerAddress, uint32 integratorIndex);
    event BillingStatusUpdated(uint32 integeratorIndex, bool status);
    event ConfigurationStatusUpdated(uint32 integratorIndex, bool status);
    event EnableIntegratorBilling(uint32 integratorIndex);
    event DisableIntegratorBilling(uint32 integratorIndex);
    event UpdateIntegratorTicketCount(uint32 integratorIndex, uint256 activeTicketCount);
    event UpdateIntegratorPrice(uint32 integratorIndex, uint256 price);
    event UpdateIntegratorName(uint32 integratorIndex, string name);
    event UpdateIntegratorOnCredit(uint32 integratorIndex, bool onCredit);

    function fuelToken() external returns (IERC20);

    function basicTaxRate() external returns (uint24);

    function spentFuel() external returns (uint256, uint256, uint32);

    function integratorCount() external returns (uint32);

    function topUpIntegrator(
        uint32 _integratorIndex,
        address _sender,
        uint256 _amount,
        uint256 _price
    ) external returns (uint256);

    function reserveFuelPrimarySale(
        address _relayerAddress,
        IEventImplementation.TicketAction[] memory _ticketActions
    ) external returns (uint256, uint256);

    function reserveFuelSecondarySale(
        address _relayerAddress,
        IEventImplementation.TicketAction[] memory _ticketActions
    ) external returns (uint256, uint256);

    function spendBasicAction(address _relayerAddress, uint32 _actionCount) external returns (uint256, uint256);

    function spendTicketReserved(address _relayerAddress, uint32 _ticketCount) external returns (uint256, uint256);

    function collectSalesTaxFuel() external;

    function correctAccountBalance(
        uint32 _integratorIndex,
        uint256 _newAvailableFuel,
        uint256 _newReservedFuel
    ) external;

    function setupIntegrator(
        string calldata _name,
        address _relayerAddress,
        DynamicRates calldata _dynamicRates,
        uint256 _price
    ) external;

    function activateIntegrator(uint32 _integratorIndex) external;

    function disableIntegrator(uint32 _integratorIndex) external;

    function addRelayer(address _relayerAddress, uint32 _integratorIndex) external;

    function removeRelayer(address _relayerAddress) external;

    function setDynamicRates(uint32 _integratorIndex, DynamicRates memory dynamicRates) external;

    function setProtocolRates(DynamicRates memory dynamicRates) external;

    function setSalesTaxFuelDestination(address _salesTaxFuelDestination) external;

    function enableIntegratorBilling(uint32 _integratorIndex) external;

    function disableIntegratorBilling(uint32 _integratorIndex) external;

    function setBasicTaxRate(uint24 _basicTaxRate) external;

    function setSpentFuel(SpentFuel calldata _spentFuel, uint256 _spentFuelOnCredit) external;

    function migrateEconomicsData() external returns (IntegratorData[] memory, DynamicRates[] memory);

    function emergencyWithdraw(address _asset, address _to, uint256 _amount) external;

    function setBillingStatus(uint32 _integratorIndex, bool status) external;

    function setConfigurationStatus(uint32 _integratorIndex, bool status) external;

    function setIntegratorPrice(uint32 _integratorIndex, uint256 _price) external;
}
