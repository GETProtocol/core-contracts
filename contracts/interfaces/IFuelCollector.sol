// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IFuelRouter } from "./IFuelRouter.sol";

interface IFuelCollector {
    event FuelReceived(uint256 amount, uint256 protocolFuel, uint256 treasuryFuel, uint256 stakersFuel);
    event FuelDistributed(uint256 indexed protocol, uint256 indexed treasury, uint256 indexed stakers);

    function receiveFuel(uint256 _amount, uint256 _protocolFuel, uint256 _treasuryFuel, uint256 _stakersFuel) external;

    function distributeFuel() external;
}
