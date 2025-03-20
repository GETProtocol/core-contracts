// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { IRouterRegistry } from "./interfaces/IRouterRegistry.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IEventEmitter } from "./interfaces/IEventEmitter.sol";
import { IActionsProcessor, IEventImplementation, IFuelRouter } from "./interfaces/IActionsProcessor.sol";
import { IEventERC721CStorageProxy } from "./interfaces/IEventERC721CStorageProxy.sol";

/**
 * @title ActionsProcessor Contract
 * @notice Contract responsible for processing ticket actions
 * @dev All EventImplementations will centralize their ticket actions here
 */
contract ActionsProcessor is IActionsProcessor, OwnableUpgradeable, UUPSUpgradeable, AuthModifiers {
    IRegistry public registry;
    IEventEmitter public eventEmitter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // solhint-disable-next-line func-name-mixedcase
    function __ActionsProcessor_init(address _registry) external initializer {
        __AuthModifiers_init(_registry);
        __ActionsProcessor_init_unchained(_registry);
        eventEmitter = IEventEmitter(registry.eventEmitterAddress());
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ActionsProcessor_init_unchained(address _registry) internal initializer {
        registry = IRegistry(_registry);
    }

    /**
     * @notice Process primary sale of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     * @param _router Address of the FuelRouter contract
     */
    function primarySale(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds,
        IFuelRouter _router
    ) external override hasEventRole(msg.sender) {
        _primarySale(_storageProxy, _ticketActions, _actionIds, _router);
    }

    /**
     * @notice Process secondary sale of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     * @param _router Address of the FuelRouter contract
     */
    function secondarySale(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds,
        IFuelRouter _router
    ) external override onlyEvent {
        _secondarySale(_storageProxy, _ticketActions, _actionIds, _router);
    }

    /**
     * @notice Process scanning of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     */
    function scan(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) external override onlyEvent {
        _scan(_storageProxy, _ticketActions, _actionIds);
    }

    /**
     * @notice Process check-in of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     */
    function checkIn(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) external override onlyEvent {
        _checkIn(_storageProxy, _ticketActions, _actionIds);
    }

    /**
     * @notice Process invalidation of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     */
    function invalidate(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) external override onlyEvent {
        _invalidate(_storageProxy, _ticketActions, _actionIds);
    }

    /**
     * @notice Process claiming of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     */
    function claim(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) external override onlyEvent {
        _claim(_storageProxy, _ticketActions, _actionIds);
    }

    /**
     * @notice Process transfer of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     */
    function transfer(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) external override onlyEvent {
        _transfer(_storageProxy, _ticketActions, _actionIds);
    }

    // Internal functions for ticket actions

    /**
     * @notice Process primary sale of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     * @param _router Address of the FuelRouter contract
     */
    function _primarySale(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds,
        IFuelRouter _router
    ) internal {
        IEventImplementation.TicketAction[] memory _validTicketActions = new IEventImplementation.TicketAction[](
            _ticketActions.length
        );

        uint256 _validCount = 0;

        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            bool _shouldSkip = false;
            uint256 _tokenId = _ticketActions[i].tokenId;
            uint64 _actionId = _actionIds[i];

            // Error checks
            if (IEventERC721CStorageProxy(_storageProxy).isPrimaryBlockedStorageProxy()) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.INVENTORY_BLOCKED_PRIMARY,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }
            if (IEventERC721CStorageProxy(_storageProxy).isExistingStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.ALREADY_EXISTING,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }
            if (_ticketActions[i].to == address(0)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.MINT_TO_ZERO_ADDRESS,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }

            if (!_shouldSkip) {
                IEventImplementation(msg.sender).mint(_ticketActions[i]);
                _validTicketActions[_validCount] = _ticketActions[i];
                _validCount++;
            }
        }

        // Resize the _validTicketActions array to remove unused slots
        assembly {
            mstore(_validTicketActions, _validCount)
        }

        (uint256 _totalFuel, uint256 _protocolFuel, uint256 _totalFuelUSD, uint256 _protocolFuelUSD) = _router
            .routeFuelForPrimarySale(_validTicketActions);

        eventEmitter.emitPrimarySale(
            msg.sender,
            _validTicketActions,
            _totalFuel,
            _protocolFuel,
            _totalFuelUSD,
            _protocolFuelUSD
        );
    }

    /**
     * @notice Process secondary sale of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     * @param _router Address of the FuelRouter contract
     */
    function _secondarySale(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds,
        IFuelRouter _router
    ) internal {
        IEventImplementation.TicketAction[] memory _validTicketActions = new IEventImplementation.TicketAction[](
            _ticketActions.length
        );
        uint256 _validCount = 0;

        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            bool _shouldSkip = false;
            uint64 _actionId = _actionIds[i];

            // Error Checks
            if (IEventERC721CStorageProxy(_storageProxy).isInvalidatedStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.ALREADY_INVALIDATED,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }
            if (IEventERC721CStorageProxy(_storageProxy).isCheckedInStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.ALREADY_CHECKED_IN,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }
            if (!IEventERC721CStorageProxy(_storageProxy).isExistingStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.NON_EXISTING,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }

            if (!_shouldSkip) {
                IEventImplementation(msg.sender).transfer(
                    IEventImplementation(msg.sender).ownerOf(_tokenId),
                    _ticketActions[i].to,
                    _tokenId
                );
                _validTicketActions[_validCount] = _ticketActions[i];
                _validCount++;
            }
        }

        // Resize the _validTicketActions array to remove unused slots
        assembly {
            mstore(_validTicketActions, _validCount)
        }

        (uint256 _totalFuel, uint256 _protocolFuel, uint256 _totalFuelUSD, uint256 _protocolFuelUSD) = _router
            .routeFuelForSecondarySale(_validTicketActions);

        eventEmitter.emitSecondarySale(
            msg.sender,
            _validTicketActions,
            _totalFuel,
            _protocolFuel,
            _totalFuelUSD,
            _protocolFuelUSD
        );
    }

    /**
     * @notice Process scanning of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     */
    function _scan(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) internal {
        IEventImplementation.TicketAction[] memory _validTicketActions = new IEventImplementation.TicketAction[](
            _ticketActions.length
        );
        uint256 _validCount = 0;

        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            uint64 _actionId = _actionIds[i];
            bool _shouldSkip = false;

            if (IEventERC721CStorageProxy(_storageProxy).isScanBlockedStorageProxy()) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.INVENTORY_BLOCKED_SCAN,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }
            if (IEventERC721CStorageProxy(_storageProxy).isInvalidatedStorageProxy(_tokenId)) {
                // revert("ALREADY_INVALIDATED");
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.ALREADY_INVALIDATED,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }
            if (!IEventERC721CStorageProxy(_storageProxy).isExistingStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.NON_EXISTING,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }

            if (!_shouldSkip) {
                IEventERC721CStorageProxy(_storageProxy).setScannedFlagStorageProxy(_tokenId, true);
                _validTicketActions[_validCount] = _ticketActions[i];
                _validCount++;
            }
        }

        assembly {
            mstore(_validTicketActions, _validCount)
        }

        eventEmitter.emitScanned(msg.sender, _validTicketActions, 0, 0);
    }

    /**
     * @notice Process check-in of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     */
    function _checkIn(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) internal {
        IEventImplementation.TicketAction[] memory _validTicketActions = new IEventImplementation.TicketAction[](
            _ticketActions.length
        );
        uint256 _validCount = 0;

        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            uint64 _actionId = _actionIds[i];
            bool _shouldSkip = false;

            if (IEventERC721CStorageProxy(_storageProxy).isInvalidatedStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.ALREADY_INVALIDATED,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }
            if (IEventERC721CStorageProxy(_storageProxy).isCheckedInStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.ALREADY_CHECKED_IN,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }
            if (!IEventERC721CStorageProxy(_storageProxy).isExistingStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.NON_EXISTING,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }

            if (!_shouldSkip) {
                IEventERC721CStorageProxy(_storageProxy).setCheckedInFlagStorageProxy(_tokenId, true);
                IEventERC721CStorageProxy(_storageProxy).setUnlockedFlagStorageProxy(_tokenId, true);
                _validTicketActions[_validCount] = _ticketActions[i];
                _validCount++;
            }
        }

        assembly {
            mstore(_validTicketActions, _validCount)
        }

        eventEmitter.emitCheckedIn(msg.sender, _validTicketActions, 0, 0);
    }

    /**
     * @notice Process invalidation of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     */
    function _invalidate(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) internal {
        IEventImplementation.TicketAction[] memory _validTicketActions = new IEventImplementation.TicketAction[](
            _ticketActions.length
        );
        uint256 _validCount = 0;

        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            uint64 _actionId = _actionIds[i];
            bool _shouldSkip = false;

            if (IEventERC721CStorageProxy(_storageProxy).isInvalidatedStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.ALREADY_INVALIDATED,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }

            if (!IEventERC721CStorageProxy(_storageProxy).isExistingStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.NON_EXISTING,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }

            if (!_shouldSkip) {
                IEventERC721CStorageProxy(_storageProxy).setInvalidatedFlagStorageProxy(_tokenId, true);
                IEventImplementation(msg.sender).burn(_tokenId);
                _validTicketActions[_validCount] = _ticketActions[i];
                _validCount++;
            }
        }

        assembly {
            mstore(_validTicketActions, _validCount)
        }

        eventEmitter.emitInvalidated(msg.sender, _validTicketActions, 0, 0);
    }

    /**
     * @notice Process claiming of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     */
    function _claim(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) internal {
        IEventImplementation.TicketAction[] memory _validTicketActions = new IEventImplementation.TicketAction[](
            _ticketActions.length
        );
        uint256 _validCount = 0;

        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            uint64 _actionId = _actionIds[i];
            bool _shouldSkip = false;

            if (IEventERC721CStorageProxy(_storageProxy).isInvalidatedStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.ALREADY_INVALIDATED,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }
            if (IEventERC721CStorageProxy(_storageProxy).isClaimBlockedStorageProxy()) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.INVENTORY_BLOCKED_CLAIM,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }
            if (!IEventERC721CStorageProxy(_storageProxy).isExistingStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.NON_EXISTING,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }

            if (!_shouldSkip) {
                IEventImplementation(msg.sender).transfer(
                    IEventImplementation(msg.sender).ownerOf(_tokenId),
                    _ticketActions[i].to,
                    _tokenId
                );
                _validTicketActions[_validCount] = _ticketActions[i];
                _validCount++;
            }
        }

        assembly {
            mstore(_validTicketActions, _validCount)
        }

        eventEmitter.emitClaimed(msg.sender, _validTicketActions);
    }

    /**
     * @notice Process transfer of tickets
     * @param _ticketActions Array of ticket actions to process
     * @param _actionIds Array of action IDs corresponding to each ticket action
     */
    function _transfer(
        address _storageProxy,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds
    ) internal {
        IEventImplementation.TicketAction[] memory _validTicketActions = new IEventImplementation.TicketAction[](
            _ticketActions.length
        );
        uint256 _validCount = 0;

        for (uint256 i = 0; i < _ticketActions.length; i++) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            uint64 _actionId = _actionIds[i];
            bool _shouldSkip = false;

            if (IEventERC721CStorageProxy(_storageProxy).isInvalidatedStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.ALREADY_INVALIDATED,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }
            if (!IEventERC721CStorageProxy(_storageProxy).isExistingStorageProxy(_tokenId)) {
                eventEmitter.emitActionErrorLog(
                    _ticketActions[i],
                    IEventImplementation.ErrorFlags.NON_EXISTING,
                    _tokenId,
                    msg.sender,
                    _actionId
                );
                _shouldSkip = true;
            }

            if (!_shouldSkip) {
                IEventImplementation(msg.sender).transfer(
                    IEventImplementation(msg.sender).ownerOf(_tokenId),
                    _ticketActions[i].to,
                    _tokenId
                );
                _validTicketActions[_validCount] = _ticketActions[i];
                _validCount++;
            }
        }

        assembly {
            mstore(_validTicketActions, _validCount)
        }

        eventEmitter.emitTransfered(msg.sender, _validTicketActions);
    }

    /**
     * @notice An internal function to authorize a contract upgrade
     * @dev The function is a requirement for OpenZeppelin's UUPS upgradeable contracts
     *
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
