// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IRegistry } from "../interfaces/IRegistry.sol";
import { ITestERC20Decimals } from "./interfaces/ITestERC20Decimals.sol";

contract Test0x {
    IRegistry public registry;
    uint256 public baseTokenAmount;

    constructor(address _registry, uint256 _baseTokenAmount) {
        registry = IRegistry(_registry);
        baseTokenAmount = _baseTokenAmount * 1e6;
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        uint256 price = registry.priceOracle().price(); // normalised to 18dp
        uint256 baseTokenPrecision = 18 - (registry.topUp().baseToken().decimals());
        uint256 fuelTokenAmount = ((baseTokenAmount * 10 ** baseTokenPrecision) * 1 ether) / price;

        registry.topUp().baseToken().transferFrom(msg.sender, address(this), baseTokenAmount);
        ITestERC20Decimals(address(registry.economicsFactory().fuelToken())).mint(msg.sender, fuelTokenAmount);

        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "Transfer failed");
    }

    receive() external payable {
        (bool success, ) = payable(msg.sender).call{ value: msg.value }("");
        require(success, "Transfer failed");
    }
}
