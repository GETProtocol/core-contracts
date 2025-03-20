// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PricingFIFO } from "./abstract/PricingFIFO.sol";
import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { IEconomicsImplementation, IFuelRouter } from "./interfaces/IEconomicsImplementation.sol";
import { IRegistry, IFuelCollector } from "./interfaces/IRegistry.sol";
import { IAuth } from "./interfaces/IAuth.sol";
import { IEventEmitter } from "./interfaces/IEventEmitter.sol";

/**
 * @title EconomicsImplementation Contract
 * @author OPN Ticketing Ecosystem
 * @notice Contract responsible for accounting operations per integrtor
 * @dev Deployed by the Economics Factory contract
 */
contract EconomicsImplementation is IEconomicsImplementation, PricingFIFO, AuthModifiers {
    IRegistry public registry;
    IAuth public auth;
    IERC20 public fuelToken;
    IFuelCollector public fuelCollector;
    IEventEmitter public eventEmitter;

    address public economicsFactory;
    uint256 public protocolOverdraft;
    uint256 public treasuryOverdraft;
    uint256 public stakersOverdraft;

    uint256 public constant MIGRATION_SCALE = 1000;

    // solhint-disable-next-line func-name-mixedcase
    function __EconomicsImplementationV2_init(address _registry, address _fuelToken) public initializer {
        __AuthModifiers_init(_registry);
        __EconomicsImplementationV2_init_unchained(_registry, _fuelToken);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __EconomicsImplementationV2_init_unchained(address _registry, address _fuelToken) internal initializer {
        registry = IRegistry(_registry);
        auth = IAuth(registry.auth());
        fuelToken = IERC20(_fuelToken);
        fuelCollector = registry.fuelCollector();
        economicsFactory = msg.sender;
        eventEmitter = IEventEmitter(registry.eventEmitterAddress());
    }

    /**
     * @notice Returns the token balance of this contract
     * @dev note that it is token amount not usd amount that is returned
     */
    function fuelBalance() external view returns (uint256 _fuelBalance) {
        _fuelBalance = fuelToken.balanceOf(address(this));
    }

    /**
     * @notice Returns fuel to be routed from economics contract
     * @dev This function can only be called by a router that is approved by the integrator
     *
     * @dev Fuel can be priced according to several FIFO tiers
     *
     * @dev Accounts for fuel overdraft
     * @param _usdAmount the amount of USD to be routed
     * @param _feeType enum stating fee type
     * @return _fuelTokenAmount total amount of tokens that are deducted
     */
    function getFuelFromTicks(
        uint256 _usdAmount,
        IFuelRouter.FeeType _feeType
    ) external returns (uint256 _fuelTokenAmount) {
        require(
            registry.routerRegistry().registeredRouter(msg.sender),
            "EconomicsImplementation: ROUTER_NOT_REGISTERED"
        );
        _fuelTokenAmount = _getFuelFromTicks(_usdAmount, _feeType);
        emit FuelReservedFromTicks(_usdAmount, _fuelTokenAmount);
        eventEmitter.emitFuelReservedFromTicks(_usdAmount, _fuelTokenAmount);
    }

    /**
     * @notice Sets the overdraft enabled status to true or false
     * @param _shouldEnableOverdraft true or false boolean clause
     */
    function setOverdraftEnabledStatus(bool _shouldEnableOverdraft) external onlyIntegratorAdmin {
        overdraftEnabled = _shouldEnableOverdraft;
        emit OverdraftEnabledStatusSet(_shouldEnableOverdraft);
        eventEmitter.emitOverdraftEnabledStatusSet(_shouldEnableOverdraft);
    }

    /**
     * @notice Tops up the economics contract with fuel
     * @param _amountTokens amount of tokens topped up
     * @param _pricePerToken usd value per token topped up
     * @return _totalFuel total fuel balance in USD after topup
     */
    function topUpEconomics(
        uint256 _amountTokens,
        uint256 _pricePerToken
    ) external onlyEconomicsFactory returns (uint256 _totalFuel) {
        require(_amountTokens != 0, "PricingFIFO: amount must be > 0");
        require(_pricePerToken != 0, "PricingFIFO: price must be > 0");
        uint256 _overdraftTokens;
        fuelToken.transferFrom(msg.sender, address(this), _amountTokens);
        if (inOverdraft) {
            _overdraftTokens = _topUpIntegratorInOverdraft(_amountTokens, _pricePerToken);
            _topUpOverDraft(_overdraftTokens);
        } else {
            _topUpIntegrator(_amountTokens, _pricePerToken);
        }
        _totalFuel = fuelBalanceUsd();
        emit ToppedUp(_pricePerToken, _amountTokens);
        eventEmitter.emitToppedUp(_pricePerToken, _amountTokens);
    }

    /**
     * @notice Withdraw any token from this contract address
     * @dev A safety net for accidental token transfers
     *
     * @dev Only callable by Integrator Admin account
     * @param _token Address of the token in mind
     * @param _destination Address to withdraw tokens to
     * @param _amount Amount of tokens to withdraw
     */
    function emergencyWithdraw(address _token, address _destination, uint256 _amount) external onlyIntegratorAdmin {
        IERC20(_token).transfer(_destination, _amount);
    }

    function transferFuelToCollector(
        uint256 _totalAmount,
        uint256 _protocolFuel,
        uint256 _treasuryFuel,
        uint256 _stakersFuel
    ) external onlyFuelRouter {
        fuelToken.approve(address(fuelCollector), _totalAmount);
        fuelCollector.receiveFuel(_totalAmount, _protocolFuel, _treasuryFuel, _stakersFuel);
    }

    function _topUpOverDraft(uint256 _amount) internal {
        uint256 _totalOverdraft = protocolOverdraft + treasuryOverdraft + stakersOverdraft; //n calculated in USD
        uint256 _protocolPercentage = (protocolOverdraft * 1e18) / _totalOverdraft;
        uint256 _stakersPercentage = (stakersOverdraft * 1e18) / _totalOverdraft;
        uint256 _protocolTokens = (_protocolPercentage * _amount) / 1e18;
        uint256 _stakersTokens = (_stakersPercentage * _amount) / 1e18;
        uint256 _treasuryTokens = _amount - (_protocolTokens + _stakersTokens);

        delete protocolOverdraft;
        delete treasuryOverdraft;
        delete stakersOverdraft;

        fuelToken.approve(address(registry.fuelCollector()), _amount);
        fuelCollector.receiveFuel(_amount, _protocolTokens, _treasuryTokens, _stakersTokens);
    }

    /**
     * @notice Internal function to get fuel to be routed from top up ticks
     * @param _usdAmount the amount of USD to be routed
     * @return _fuelTokenAmount total amount of tokens that are deducted
     */
    function _getFuelFromTicks(
        uint256 _usdAmount,
        IFuelRouter.FeeType _feeType
    ) internal returns (uint256 _fuelTokenAmount) {
        // deduct the fuel from the economcics balance
        // note _fuelDeduction also returns a bool that indicates if part of the fuel was overdrafted
        uint256 overdraftedFuel_;
        (_fuelTokenAmount, overdraftedFuel_) = _fuelDeduction(_usdAmount);

        if (overdraftedFuel_ > 0) {
            if (_feeType == IFuelRouter.FeeType.PROTOCOL) {
                protocolOverdraft += overdraftedFuel_;
            } else if (_feeType == IFuelRouter.FeeType.TREASURY) {
                treasuryOverdraft += overdraftedFuel_;
            } else {
                stakersOverdraft += overdraftedFuel_;
            }
        }
    }

    function setFuelCollector(address _newFuelCollector) external override onlyEconomicsFactory {
        fuelCollector = IFuelCollector(_newFuelCollector);
    }

    /**
     * @notice Sets the EventEmitter contract address
     * @dev Would throw if `_eventEmitter` is not a contract address
     *
     * @dev can only be called by contract owner
     * @param _eventEmitter EventEmitter contract address
     */
    function setEventEmitter(address _eventEmitter) external onlyIntegratorAdmin {
        eventEmitter = IEventEmitter(_eventEmitter);
    }

    function migrateData(MigrationData calldata _migrationData) external onlyEconomicsFactory {
        // Migrate tick data
        for (uint256 i = 0; i < _migrationData.topUpTicks.length; i++) {
            topUpTicks[i] = _migrationData.topUpTicks[i];
            emit TickUpdated(i, _migrationData.topUpTicks[i]);
        }
        
        // Set active tick index
        activeTickIndex = _migrationData.activeTickIndex;
        emit CurrentActiveTick(_migrationData.activeTickIndex);

        // Set total values
        totalTokensToppedUp = _migrationData.totalTokensToppedUp;
        totalTokensSpent = _migrationData.totalTokensSpent;
        totalUsdToppedUp = _migrationData.totalUsdToppedUp;
        totalUsdSpent = _migrationData.totalUsdSpent;
        emit UpdatedStorage(totalTokensToppedUp, totalTokensSpent);

        // Set overdraft related values
        overdraftEnabled = _migrationData.overdraftEnabled;
        inOverdraft = _migrationData.inOverdraft;
        currentOverdraftUsd = _migrationData.currentOverdraftUsd;
        protocolOverdraft = _migrationData.protocolOverdraft;
        treasuryOverdraft = _migrationData.treasuryOverdraft;
        stakersOverdraft = _migrationData.stakersOverdraft;

        // Verify migration
        uint256 getBalance = fuelToken.balanceOf(address(this));
        emit MigrationComplete(getBalance, _migrationData.totalTokensToppedUp - _migrationData.totalTokensSpent);
    }
}
