// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface ITopUp {
    event ToppedUpCustodial(
        uint32 indexed integratorIndex,
        address indexed debitedAccount,
        uint256 availableFuel,
        uint256 amountFuel,
        uint256 price,
        bytes32 externalId
    );

    event ToppedUpCustodial0x(
        uint32 indexed integratorIndex,
        address indexed debitedAccount,
        uint256 availableFuel,
        uint256 amountFuel,
        uint256 price,
        bytes32 externalId
    );

    event ToppedUpNonCustodial(
        uint32 indexed integratorIndex,
        address indexed debitedAccount,
        uint256 availableFuel,
        uint256 amountFuel,
        uint256 price
    );
    event UpdateBaseToken(address old, address updated);
    event UpdateWeth(address old, address updated);
    event UpdateRouter(address old, address updated);
    event UpdateOracle(address old, address updated);

    function baseToken() external returns (IERC20Metadata);

    function weth() external returns (IERC20);

    function router() external returns (ISwapRouter);

    function topUpCustodial(
        uint32 _integratorIndex,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes32 _externalId
    ) external;

    function topUpNonCustodial(uint32 _integratorIndex, uint256 _amountFuel) external;

    function pause() external;

    function unpause() external;

    function setBaseToken(address _baseToken) external;

    function setWeth(address _weth) external;

    function setRouter(address _router) external;

    function setApprovals() external;
}
