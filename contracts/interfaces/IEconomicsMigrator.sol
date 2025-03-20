// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEconomicsMigrator {
    function migrateForIntegrator(address _integrator, uint256 _getAmount) external returns (uint256);

    function withdrawalOpnToOwner(uint256 _amount) external;

    function setEconomicsFactory(address _economicsFactory) external;

    function withdrawalAllOpnToOwner() external;

    function withdrawAllGetToOwner() external;

    function functionCallBackup(address _target, bytes memory _data) external;

    event EconomicsFactorySet(address economicsFactory);

    event WithdrawalOpnToOwner(uint256 amount);

    event WithdrawalGETToOwner(uint256 amount);

    event FactoryUpgraded();

    event EconomicsUpgraded(address implementationBefore, address implementationAfter);

    event MigrationCompleted();

    event AllMigrationCalled();

    event RegistryConfigured(
        address topUpAddress,
        address fuelCollectorAddress,
        address protocolFeeDestination,
        address fuelBridgeReceiverAddress,
        address stakingContractAddress,
        address treasuryFeeDestination
    );

    event MigrationInitiated(address indexed integrator, uint256 getAmount, uint256 opnAmount);

    event EventFactoryUpgraded(address indexed implementationBefore, address indexed implementationAfter);
}
