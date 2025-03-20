// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { IPriceOracle } from "./interfaces/IPriceOracle.sol";

/**
 * @title PriceOracle Contract
 * @author OPN Ticketing Ecosystem
 * @notice Contract responsible for $OPN price delivery during Non-Custodial Integrator top ups
 */
contract PriceOracle is IPriceOracle, Ownable, AuthModifiers {
    uint256 public price;
    uint32 public lastUpdateTimestamp;

    /**
     * @notice Constructor function
     * @param _registry Registry contract address
     * @param _price $OPN price normalised to 18 decimal places
     */
    constructor(address _registry, uint256 _price)Ownable(msg.sender) {
        price = _price;
        __AuthModifiers_init_unchained(_registry);
        lastUpdateTimestamp = uint32(block.timestamp);
    }

    /**
     * @notice Set's $OPN price
     * @param _price $OPN price normalised to 18 decimal places
     */
    function setPrice(uint256 _price) external onlyPriceOracle {
        emit UpdatePrice(price, _price);
        price = _price;
        lastUpdateTimestamp = uint32(block.timestamp);
    }
}
