// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPaymentSplitterInitializable {
    // Events

    event NativeFundsReleased(uint256[] amounts, address[] payees);
    event ERC20FundsReleased(uint256[] amounts, address[] payees);

    function totalShares() external view returns (uint256);
    function totalReleased() external view returns (uint256);
    function totalReleased(IERC20 token) external view returns (uint256);
    function shares(address account) external view returns (uint256);
    function released(address account) external view returns (uint256);
    function released(IERC20 token, address account) external view returns (uint256);
    function payee(uint256 index) external view returns (address);
    function releasable(address account) external view returns (uint256);
    function releasable(IERC20 token, address account) external view returns (uint256);
    function initializePaymentSplitter(
        address _eventAddress,
        address[] calldata payees,
        uint256[] calldata shares_,
        address _registryAddress
    ) external;
    function release(address payable account) external returns (uint256);
    function release(IERC20 token, address account) external returns (uint256);
}
