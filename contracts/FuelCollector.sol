// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IFuelCollector, IFuelRouter } from "./interfaces/IFuelCollector.sol";
import { IRegistry } from "./interfaces/IFuelRouter.sol";

/**
 * @title FuelCollector Contract
 * @author Open Ticketing Ecosystem
 * @notice Collects fuel and distributes to the fuel destinations
 */
contract FuelCollector is IFuelCollector, OwnableUpgradeable, UUPSUpgradeable {
    IERC20 public fuelToken;
    IRegistry public registry;
    mapping(IFuelRouter.FeeType => uint256) public destinationBalances;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // solhint-disable-next-line func-name-mixedcase
    function __FuelCollector_init(address _owner, address _asset, address _registry) public initializer {
        __Ownable_init(msg.sender);
        __FuelCollector_init_unchained(_owner, _asset, _registry);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __FuelCollector_init_unchained(address _owner, address _asset, address _registry) public initializer {
        fuelToken = IERC20(_asset);
        _transferOwnership(_owner);
        registry = IRegistry(_registry);
    }

    /**
     * @notice Receives fuel for a  fuel destination
     * @param _amount Amount of fuel received
     * @param _protocolFuel  Protocol fuel amount
     * @param _treasuryFuel Treasury fuel amount
     * @param _stakersFuel Stakers fuel amount
     */
    function receiveFuel(uint256 _amount, uint256 _protocolFuel, uint256 _treasuryFuel, uint256 _stakersFuel) external {
        require(_amount == (_protocolFuel + _treasuryFuel + _stakersFuel), "FuelCollector:AMOUNT_DISTRIBUTION_ERROR");
        // transfer in fuel
        if (_amount > 0) {
            fuelToken.transferFrom(msg.sender, address(this), _amount);

            // update fuel balances
            destinationBalances[IFuelRouter.FeeType.PROTOCOL] += _protocolFuel;
            destinationBalances[IFuelRouter.FeeType.TREASURY] += _treasuryFuel;
            destinationBalances[IFuelRouter.FeeType.STAKERS] += _stakersFuel;

            emit FuelReceived(_amount, _protocolFuel, _treasuryFuel, _stakersFuel);
        }
    }

    /**
     * @notice Distributes fuel to fuel destinations
     */
    function distributeFuel() external {
        uint256 _protocolBalance = destinationBalances[IFuelRouter.FeeType.PROTOCOL];
        uint256 _treasuryBalance = destinationBalances[IFuelRouter.FeeType.TREASURY];
        uint256 _stakersBalance = destinationBalances[IFuelRouter.FeeType.STAKERS];

        delete destinationBalances[IFuelRouter.FeeType.PROTOCOL];
        delete destinationBalances[IFuelRouter.FeeType.TREASURY];
        delete destinationBalances[IFuelRouter.FeeType.STAKERS];

        fuelToken.transfer(registry.protocolFeeDestination(), _protocolBalance);
        fuelToken.transfer(registry.treasuryFeeDestination(), _treasuryBalance);

        // split stakers fuel
        uint256 _ethereumBalance = registry.stakingBalanceOracle().ethereumBalance();
        uint256 _polygonBalance = registry.stakingBalanceOracle().polygonBalance();
        uint256 _amountToEthereum = (_ethereumBalance * _stakersBalance) / (_ethereumBalance + _polygonBalance);
        uint256 _amountToPolygon = _stakersBalance - _amountToEthereum;

        fuelToken.transfer(registry.fuelBridgeReceiverAddress(), _amountToEthereum);
        fuelToken.transfer(registry.stakingContractAddress(), _amountToPolygon);

        emit FuelDistributed(_protocolBalance, _treasuryBalance, _stakersBalance);
    }

    /**
     * @notice Withdraws an asset on this contract to a given address
     *
     * @dev It can only be called by the contract owner
     * @param _asset contract address of a particular asset
     * @param _to address the asset is sent to
     * @param _amount amount of the asset to be sent
     */
    function emergencyWithdraw(address _asset, address _to, uint256 _amount) external onlyOwner {
        IERC20(_asset).transfer(_to, _amount);
    }

    /**
     * @notice An internal function to authorize a contract upgrade
     * @dev The function is a requirement for OpenZeppelin's UUPS upgradeable contracts
     *
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
