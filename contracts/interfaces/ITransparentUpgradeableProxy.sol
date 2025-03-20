// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

interface ITransparentUpgradeableProxy is IERC1967 {
    function upgradeToAndCall(address, bytes calldata) external payable;
}
