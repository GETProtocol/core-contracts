// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
// import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { IPriceOracle } from "./interfaces/IPriceOracle.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { ITopUp } from "./interfaces/ITopUp.sol";
import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title TopUp Contract
 * @author Open Ticketing Ecosystem
 * @notice Contract responsible for integrator fuel top ups
 * @dev Supports two integrator top ups; Custodian and Non-Custodial
 */

contract TopUp is
    ITopUp,
    OwnableUpgradeable,
    PausableUpgradeable,
    AuthModifiers,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    // using AddressUpgradeable for address;

    IRegistry private registry;
    IERC20Metadata public baseToken;
    IERC20 public weth;
    ISwapRouter public router;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initialization function for proxy contract
     * @param _registry Registry contract address
     * @param _baseToken Topup base token address; typically USDC
     * @param _weth Wrapped Ether token address
     * @param _router SwapRouter contract address
     */
    // solhint-disable-next-line func-name-mixedcase
    function __TopUp_init(address _registry, address _baseToken, address _weth, address _router) public initializer {
        __Context_init();
        __Ownable_init(msg.sender);
        __AuthModifiers_init(_registry);
        __TopUp_init_unchained(_registry, _baseToken, _weth, _router);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __TopUp_init_unchained(
        address _registry,
        address _baseToken,
        address _weth,
        address _router
    ) public initializer {
        registry = IRegistry(_registry);
        baseToken = IERC20Metadata(_baseToken);
        weth = IERC20(_weth);
        router = ISwapRouter(_router);
    }

    function _calculatePrice(uint256 _amountA, uint256 _amountB) internal view returns (uint256 _swapPrice) {
        _swapPrice = (_amountA * 1e18 * 10 ** (18 - baseToken.decimals())) / _amountB;
    }

    /**
     * @notice Internal function to swap tokens via the SwapRouter contract
     * @dev called by the topUpCustodial function
     * @param _amountIn amount of the token to be swapped for another
     * @param _amountOutMin minimum output of swapped token
     * @return _swapInfo amount of swapped tokens and swap price normalised to 18 decimal places
     */
    function _swapFromPair(uint256 _amountIn, uint256 _amountOutMin) internal whenNotPaused returns (uint256, uint256) {
        require(baseToken.transferFrom(msg.sender, address(this), _amountIn), "TopUp: transferFrom failed");
        require(baseToken.approve(address(router), _amountIn), "TopUp: approval failed");

        ISwapRouter.ExactInputSingleParams memory _params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(baseToken),
            tokenOut: address(registry.economicsFactory().fuelToken()),
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: _amountOutMin,
            sqrtPriceLimitX96: 0
        });

        uint256 _amountOut = router.exactInputSingle(_params);

        /// Normalise swap price to 18dp
        uint256 _swapPrice = _calculatePrice(_amountIn, _amountOut);
        return (_amountOut, _swapPrice);
    }

    /**
     * @dev  Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
     * @param _sellToken The `sellTokenAddress` field from the API response.
     * @param _buyToken The `buyTokenAddress` field from the API response.
     * @param _spender The `allowanceTarget` field from the API response.
     * @param _swapTarget The `to` field from the API response.
     * @param _swapCallData The `data` field from the API response.
     * @return _boughtAmount Amount of token bought
     * @return _swapPrice Price of token swap
     */
    // solhint-disable-next-line max-line-length
    /// Actual implementation by 0x can be found here: https://github.com/0xProject/0x-api-starter-guide-code/blob/900a3264847c81aa75070fc43c996b2012402597/contracts/SimpleTokenSwap.sol#L65
    function _fillQuote(
        IERC20 _sellToken,
        IERC20 _buyToken,
        address _spender,
        address payable _swapTarget,
        bytes calldata _swapCallData
    ) internal returns (uint256, uint256) {
        // Here we transfer the full baseToken balance of msg.sender to the TopUp contract.
        require(
            baseToken.transferFrom(msg.sender, address(this), baseToken.balanceOf(msg.sender)),
            "TopUp: transferFrom failed"
        );

        uint256 _boughtAmount = _buyToken.balanceOf(address(this));
        uint256 _soldAmount = _sellToken.balanceOf(address(this));

        require(_sellToken.approve(_spender, type(uint256).max), "TopUp: approve call failed");

        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = _swapTarget.call{ value: msg.value }(_swapCallData);
        require(_success, "TopUp: swap call failed");

        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "TopUp: Transfer failed");
        _boughtAmount = _buyToken.balanceOf(address(this)) - _boughtAmount;
        _soldAmount = _soldAmount - _sellToken.balanceOf(address(this));
        uint256 _swapPrice = _calculatePrice(_soldAmount, _boughtAmount);

        // Finally we refund the leftover baseToken balance to msg.sender.
        require(baseToken.transfer(msg.sender, baseToken.balanceOf(address(this))), "TopUp: refund failed");
        return (_boughtAmount, _swapPrice);
    }

    /**
     * @notice Custodial integrator top up
     * @dev tops up an integrator on-ramp
     *
     * @dev Fiat USD is swapped for USDC which is eventually swapped for $OPN
     * @param _integratorIndex integrator index in question
     * @param _amountIn amount of USDC to be swapped for $OPN
     * @param _amountOutMin minimum expected $OPN
     * @param _externalId transaction identification
     */
    function topUpCustodial(
        uint32 _integratorIndex,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes32 _externalId
    ) external whenNotPaused onlyCustodialTopUp {
        (uint256 _amountFuel, uint256 _swapPrice) = _swapFromPair(_amountIn, _amountOutMin);

        uint256 _availableFuel = registry.economicsFactory().topUpIntegrator(
            _integratorIndex,
            address(this),
            _amountFuel,
            _swapPrice
        );
        emit ToppedUpCustodial(_integratorIndex, msg.sender, _availableFuel, _amountFuel, _swapPrice, _externalId);
    }

    /**
     * @notice Custodial topup using 0x Protocol for token swaps
     * @dev Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
     *
     * @dev Must attach ETH equal to the `value` field from the API response.
     * @param _integratorIndex integrator index in question
     * @param _externalId transaction identification
     * @param _spender The `allowanceTarget` field from the API response.
     * @param _swapTarget The `to` field from the API response.
     * @param _swapCallData The `data` field from the API response.
     */
    function topUpCustodial0x(
        uint32 _integratorIndex,
        bytes32 _externalId,
        address _spender,
        address payable _swapTarget,
        bytes calldata _swapCallData
    ) external payable whenNotPaused onlyCustodialTopUp nonReentrant {
        (uint256 _amountFuel, uint256 _swapPrice) = _fillQuote(
            IERC20(baseToken),
            IERC20(registry.economicsFactory().fuelToken()),
            _spender,
            _swapTarget,
            _swapCallData
        );

        uint256 _availableFuel = registry.economicsFactory().topUpIntegrator(
            _integratorIndex,
            address(this),
            _amountFuel,
            _swapPrice
        );

        emit ToppedUpCustodial0x(_integratorIndex, msg.sender, _availableFuel, _amountFuel, _swapPrice, _externalId);
    }

    /**
     * @notice Non-Custodial integrator top up
     * @dev tops up an integrator directly with $OPN
     * @param _integratorIndex integrator index in question
     * @param _amountFuel amount of $OPN for top up
     */
    function topUpNonCustodial(uint32 _integratorIndex, uint256 _amountFuel) external {
        // note removed whenNotPaused modifier
        // Add logging to see if this function is being called
        emit LogTopUpNonCustodial(_integratorIndex, _amountFuel, msg.sender);

        // Add more logging as needed to debug
        uint256 _price = registry.priceOracle().price();
        uint256 _availableFuel = registry.economicsFactory().topUpIntegrator(
            _integratorIndex,
            msg.sender,
            _amountFuel,
            _price
        );
        emit ToppedUpNonCustodial(_integratorIndex, msg.sender, _availableFuel, _amountFuel, _price);
    }

    event LogTopUpNonCustodial(uint32 indexed integratorIndex, uint256 amountFuel, address indexed sender);

    /** @notice This pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /** @notice This halts the pause
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Set's the address of the base token used in topUpCustodial
     * @dev this most likely is USDC
     * @param _baseToken contract address for the token
     */
    function setBaseToken(address _baseToken) external isContract(_baseToken) onlyOwner {
        emit UpdateBaseToken(address(baseToken), _baseToken);
        baseToken = IERC20Metadata(_baseToken);
    }

    /**
     * @notice Set's the address for WETH used in topUpCustodial
     * @dev the base token is swapped for WETH and WETH for $OPN in a custodial top up
     * @param _weth WETH contract address
     */
    function setWeth(address _weth) external isContract(_weth) onlyOwner {
        emit UpdateWeth(address(weth), _weth);
        weth = IERC20(_weth);
    }

    /**
     * @notice Set's the address for SwapRouter contract
     * @dev The router performs the USDC to $OPN swap in a custodial top up
     * @param _router router contract address
     */
    function setRouter(address _router) external isContract(_router) onlyOwner {
        emit UpdateRouter(address(router), _router);
        router = ISwapRouter(_router);
    }

    /**
     * @notice Gives maximum allowance for $OPN on the Economics contract
     */
    function setApprovals() external onlyOwner {
        registry.economicsFactory().fuelToken().approve(address(registry.economicsFactory()), type(uint256).max);
    }

    /**
     * @dev Filters out non-contract addresses
     */
    modifier isContract(address _account) {
        require(_account.code.length > 0, "TopUp: address is not a contract");
        _;
    }

    /**
     * @notice  A internal function to authorize a contract upgrade
     * @dev The function is a requirement for Openzeppelin's UUPS upgradeable contracts
     *
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
