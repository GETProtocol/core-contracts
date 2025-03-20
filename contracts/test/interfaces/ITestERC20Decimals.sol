// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITestERC20Decimals {
    function mint(address to, uint256 amount) external;

    function decimals() external view returns (uint8);
}
