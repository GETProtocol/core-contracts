// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IAuth is IAccessControl {
    function addIntegratorAdminToIndex(address, uint256) external;

    function removeIntegratorAdmin(address) external;

    function hasProtocolDAORole(address) external view;

    function hasEconomicsConfigurationRole(address, uint256) external view;

    function hasEventFinancingConfigurationRole(address, uint256) external view;

    function hasIntegratorAdminRole(address) external view;

    function hasEventFactoryRole(address) external view;

    function hasEventRole(address) external view;

    function hasRelayerRole(address) external view;

    function hasTopUpRole(address) external view;

    function hasCustodialTopUpRole(address) external view;

    function hasPriceOracleRole(address) external view;

    function hasStakingBalanceOracleRole(address) external view;

    function grantEventRole(address) external;

    function hasRouterRegistryRole(address) external view;

    function hasFuelRouterRole(address) external view;

    function hasEconomicsFactoryRole(address _sender) external view;

    function hasActionsProcessorRole(address) external view;
}
