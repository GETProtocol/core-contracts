// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEconomicsFactory {
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
    }

    struct IntegratorData {
        uint32 index;
        bool isBillingEnabled;
        bool isConfigured;
        string name;
        bool onCredit;
    }

    struct RelayerData {
        uint32 integratorIndex;
    }

    // Used strictly for data migration between Economics and EconomicsFactory contracts
    struct IntegratorRelayerData {
        uint256 integratorIndex;
        address[] relayers;
    }

    event UpdateIntegratorOnCredit(uint32 integratorIndex, bool onCredit);

    event UpdateSalesTaxFuelDestination(address salesTaxFuelDestination);

    event UpdateFuelToken(address old, address updated);

    event EnableIntegratorBilling(uint32 integratorIndex);

    event UpdateDynamicRates(uint32 indexed integratorIndex, DynamicRates dynamicRates);

    event IntegratorToppedUp(
        uint32 indexed integratorIndex,
        address economicsContract,
        uint256 indexed total,
        uint256 topUpPrice
    );

    event UpdateProtocolRates(DynamicRates protocolRates);

    event IntegratorActivated(uint32 indexed integratorIndex);

    event ConfigurationStatusUpdated(uint32 indexed integratorIndex, bool status);

    event BillingStatusUpdated(uint32 indexed integratorIndex, bool status);

    event IntegratorConfigured(
        uint256 indexed integratorIndex,
        string name,
        address relayerAddress,
        bool isDigitalTwin,
        DynamicRates dynamicRates
    );
    event IntegratorDisabled(uint32 indexed integratorIndex);

    event RelayerRemoved(address indexed relayerAddress, uint256 indexed integratorIndex);

    event EconomicsContractDeployed(address indexed economicsAddress, uint256 indexed integratorIndex);

    event RelayerAdded(address indexed relayerAddress, uint256 indexed integratorIndex);

    event DisableIntegratorBilling(uint32 integratorIndex);

    event IntegratorNameSet(uint256 integratorIndex, string name);

    event EventEmitterSet(address indexed eventEmitter);

    function relayerToIndex(address relayerAddress) external returns (uint32 integratorIndex);

    function isIntegratorDigitalTwin(address relayerAddress) external view returns (bool isDigitalTwin);

    function fuelToken() external view returns (IERC20);

    function wasUpgradeSuccessFull() external view returns (bool);

    function economicsContracts(uint256 integratorIndex) external view returns (address);

    function returnDynamicRatesOfIntegrator(
        uint256 integratorIndex
    ) external view returns (DynamicRates memory dynamicRates);

    function setupIntegrator(
        string calldata name,
        address relayerAddress,
        DynamicRates calldata dynamicRates,
        bool isDigitalTwin
    ) external returns (address economicsAddress);

    function topUpIntegrator(
        uint256 integratorIndex,
        address sender,
        uint256 total,
        uint256 price
    ) external returns (uint256);

    function setFuelToken(address _fuelToken) external;

    function initialize() external;

    function isIntegratorConfigured(uint256 integratorIndex) external view returns (bool isConfigured);

    function isIntegratorEnabled(uint256 integratorIndex) external view returns (bool isEnabled);

    function configuredIntegratorIndex(address relayerAddress) external view returns (uint256 integratorIndex);

    function configuredIntegratorEconomics(uint256 integratorIndex) external view returns (address economicsAddress);
}
