// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { EventERC721CUpgradeableBase } from "./abstract/EventERC721CUpgradeableBase.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IEventImplementation, IERC721 } from "./interfaces/IEventImplementation.sol";
import { IRouterRegistry } from "./interfaces/IRouterRegistry.sol";
import { IFuelRouter } from "./interfaces/IFuelRouter.sol";
import { IRegistry, IActionsProcessor } from "./interfaces/IRegistry.sol";
import { IEventEmitter } from "./interfaces/IEventEmitter.sol";
// import { IEventERC721CStorageProxy } from "./interfaces/IEventERC721CStorageProxy.sol";

contract EventImplementation is IEventImplementation, EventERC721CUpgradeableBase {
    using Strings for uint256;
    IRegistry private registry;
    address private eventEmitter;
    address private actionsProcessor;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function __EventImplementation_init(
        string calldata _name_,
        string calldata _symbol_,
        address _registry,
        address _storageProxy
    ) external initializer {
        __EventERC721CUpgradeableBase_init(_name_, _symbol_, _storageProxy);
        __EventImplementation_init_unchained(_registry);
    }

    modifier onlyRelayer() {
        registry.auth().hasRelayerRole(msg.sender);
        _;
    }

    modifier onlyEventFactory() {
        registry.auth().hasEventFactoryRole(msg.sender);
        _;
    }

    function __EventImplementation_init_unchained(address _registry) internal initializer {
        registry = IRegistry(_registry);
        eventEmitter = registry.eventEmitterAddress();
        actionsProcessor = address(registry.actionsProcessor());
    }
    /**
     * @notice Performs all ticket interractions via an integrator's relayer
     * @dev Performs ticket actions based on the array of action counts
     *
     * @dev Each value in the actionCounts array corresponds to the number of a specific ticket action to be performed
     *
     * @dev Can only be called by an integrator's relayer
     * @param _ticketActions array of TicketAction structs for which a ticket action is performed
     * @param _actionCounts integer array corresponding to specific ticket action to be performed on the ticketActions
     */
    function batchActions(
        TicketAction[] calldata _ticketActions,
        uint8[] calldata _actionCounts,
        uint64[] calldata _actionIds
    ) external onlyRelayer {
        _batchActions(_ticketActions, _actionCounts, _actionIds, msg.sender);
    }

    /**
     * @notice Performs all ticket interractions via EventFactory contract
     * @dev Performs ticket actions based on the array of action counts
     *
     * @dev Each value in the actionCounts array corresponds to the number of a specific ticket action to be performed
     *
     * @dev Can only be called by an EventFactory contract
     * @param _ticketActions array of TicketAction structs for which a ticket action is performed
     * @param _actionCounts integer array corresponding to specific ticket action to be performed on the ticketActions
     */
    function batchActionsFromFactory(
        TicketAction[] calldata _ticketActions,
        uint8[] calldata _actionCounts,
        uint64[] calldata _actionIds,
        address _messageSender
    ) external onlyEventFactory {
        _batchActions(_ticketActions, _actionCounts, _actionIds, _messageSender);
    }

    // solhint-disable-next-line code-complexity
    function _batchActions(
        TicketAction[] calldata _ticketActions,
        uint8[] calldata _actionCounts,
        uint64[] calldata _actionIds,
        address _messageSender
    ) internal {
        IRouterRegistry _routerRegistry = IRouterRegistry(registry.routerRegistry());

        IFuelRouter _router = IFuelRouter(_routerRegistry.returnEventToRouter(address(this), _messageSender));

        uint256 _start = 0;

        for (uint256 _actionType = 0; _actionType < _actionCounts.length; ++_actionType) {
            uint256 _end = _start + _actionCounts[_actionType];

            if (_actionCounts[_actionType] != 0) {
                if (_actionType == 0) {
                    _primarySale(_ticketActions[_start:_end], _actionIds, _router);
                } else if (_actionType == 1) {
                    _secondarySale(_ticketActions[_start:_end], _actionIds, _router);
                } else if (_actionType == 2) {
                    _scan(_ticketActions[_start:_end], _actionIds);
                } else if (_actionType == 3) {
                    _checkIn(_ticketActions[_start:_end], _actionIds);
                } else if (_actionType == 4) {
                    _invalidate(_ticketActions[_start:_end], _actionIds);
                } else if (_actionType == 5) {
                    _claim(_ticketActions[_start:_end], _actionIds);
                } else if (_actionType == 6) {
                    _transfer(_ticketActions[_start:_end], _actionIds);
                }
                _start = _end;
            }
        }
    }

    /**
     * @notice Initiates a primary sale for a batch of tickets
     * @param _ticketActions Array of TicketAction structs containing ticket details
     * @param _actionIds Array of action IDs for the primary sale
     * @param _router The fuel router to use for the primary sale
     */
    function _primarySale(
        TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds,
        IFuelRouter _router
    ) internal {
        IActionsProcessor _actionsProcessor = registry.actionsProcessor();
        _actionsProcessor.primarySale(address(storageProxy), _ticketActions, _actionIds, _router);
    }

    /**
     * @notice Initiates a secondary sale for a batch of tickets
     * @param _ticketActions Array of TicketAction structs containing ticket details
     * @param _actionIds Array of action IDs for the secondary sale
     * @param _router The fuel router to use for the secondary sale
     */
    function _secondarySale(
        TicketAction[] calldata _ticketActions,
        uint64[] calldata _actionIds,
        IFuelRouter _router
    ) internal {
        IActionsProcessor _actionsProcessor = registry.actionsProcessor();
        _actionsProcessor.secondarySale(address(storageProxy), _ticketActions, _actionIds, _router);
    }

    /**
     * @notice Initiates a scan for a batch of tickets
     * @param _ticketActions Array of TicketAction structs containing ticket details
     * @param _actionIds Array of action IDs for the scan
     */
    function _scan(TicketAction[] calldata _ticketActions, uint64[] calldata _actionIds) internal {
        IActionsProcessor _actionsProcessor = registry.actionsProcessor();
        _actionsProcessor.scan(address(storageProxy), _ticketActions, _actionIds);
    }

    /**
     * @notice Initiates a check-in for a batch of tickets
     * @param _ticketActions Array of TicketAction structs containing ticket details
     * @param _actionIds Array of action IDs for the check-in
     */
    function _checkIn(TicketAction[] calldata _ticketActions, uint64[] calldata _actionIds) internal {
        IActionsProcessor _actionsProcessor = registry.actionsProcessor();
        _actionsProcessor.checkIn(address(storageProxy), _ticketActions, _actionIds);
    }

    /**
     * @notice Initiates an invalidation for a batch of tickets
     * @param _ticketActions Array of TicketAction structs containing ticket details
     * @param _actionIds Array of action IDs for the invalidation
     */
    function _invalidate(TicketAction[] calldata _ticketActions, uint64[] calldata _actionIds) internal {
        IActionsProcessor _actionsProcessor = registry.actionsProcessor();
        _actionsProcessor.invalidate(address(storageProxy), _ticketActions, _actionIds);
    }

    /**
     * @notice Initiates a claim for a batch of tickets
     * @param _ticketActions Array of TicketAction structs containing ticket details
     * @param _actionIds Array of action IDs for the claim
     */
    function _claim(TicketAction[] calldata _ticketActions, uint64[] calldata _actionIds) internal {
        IActionsProcessor _actionsProcessor = registry.actionsProcessor();
        _actionsProcessor.claim(address(storageProxy), _ticketActions, _actionIds);
    }

    function setEventData(IEventImplementation.EventData calldata _eventData) external onlyEventFactory {
        storageProxy.setEventDataStorageProxy(_eventData);
        IEventEmitter(eventEmitter).emitEventDataSet(_eventData);
    }

    function updateEventData(IEventImplementation.EventData calldata _eventData) external onlyRelayer {
        storageProxy.updateEventDataStorageProxy(_eventData);
        IEventEmitter(eventEmitter).emitEventDataUpdated(_eventData);
    }

    function setFinancing(IEventImplementation.EventFinancing calldata _financing) external onlyEventFactory {
        storageProxy.setFinancingStorageProxy(_financing);
    }

    function setTokenRoyaltyDefault(address _receiver, uint96 _feeNominator) external onlyEventFactory {
        storageProxy.setTokenRoyaltyDefaultStorageProxy(_receiver, _feeNominator);
    }

    function setExceptionTokenRoyalty(
        address _receiver,
        uint256 _tokenId,
        uint96 _feeNominator
    ) external onlyEventFactory {
        // note if we need room, this one can be removed or called directly to the storage slot
        storageProxy.setExceptionTokenRoyaltyStorageProxy(_receiver, _tokenId, _feeNominator);
    }

    function deleteRoyaltyInfoDefault() external onlyEventFactory {
        // note if we need room, this one can be removed or called directly to the storage slot
        storageProxy.deleteRoyaltyInfoDefaultStorageProxy();
    }

    function deleteRoyaltyException(uint256 _tokenId) external onlyEventFactory {
        // note if we need room, this one can be removed or called directly to the storage slot
        storageProxy.deleteRoyaltyExceptionStorageProxy(_tokenId);
    }

    /**
     * @notice Initiates a transfer for a batch of tickets
     * @param _ticketActions Array of TicketAction structs containing ticket details
     * @param _actionIds Array of action IDs for the transfer
     */
    function _transfer(TicketAction[] calldata _ticketActions, uint64[] calldata _actionIds) internal {
        IActionsProcessor _actionsProcessor = registry.actionsProcessor();
        _actionsProcessor.transfer(address(storageProxy), _ticketActions, _actionIds);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) {
            if (!storageProxy.isInvalidatedStorageProxy(_tokenId)) {
                revert("ERC721Metadata: URI query for nonexistent token");
            }
        }
        IEventImplementation.EventData memory eventData = storageProxy.getEventDataStorageProxy();
        string memory _uri = _baseURI();
        return
            bytes(_uri).length > 0
                ? string(abi.encodePacked(_uri, uint256(eventData.index).toString(), "/", _tokenId.toString()))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return registry.baseURI();
    }

    function ownerOf(
        uint256 _tokenId
    ) public view virtual override(IERC721, EventERC721CUpgradeableBase) returns (address _owner) {
        _owner = storageProxy.getTokenDataStorageProxy(_tokenId).owner;
        require(_owner != address(0), "ERC721: owner query for nonexistent token");
        return _owner;
    }

    function mint(TicketAction calldata _ticketAction) public override(IEventImplementation) {
        require(msg.sender == actionsProcessor, "EventImplementation: only actions processor can mint");
        _mint(_ticketAction);
    }

    function burn(uint256 _tokenId) public override(IEventImplementation) {
        require(msg.sender == actionsProcessor, "EventImplementation: only actions processor can burn");
        _burn(_tokenId);
    }

    function transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(EventERC721CUpgradeableBase, IEventImplementation) {
        require(msg.sender == actionsProcessor, "EventImplementation: only actions processor can transfer");
        super.transfer(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(EventERC721CUpgradeableBase, IERC721) {
        // check if the token is unlocked
        if (!storageProxy.isUnlockedStorageProxy(_tokenId)) {
            revert("EventImplementation: ticket must be unlocked");
        }
        return super.transferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(EventERC721CUpgradeableBase, IERC721) {
        // TODO add additional validation if needed - look into this
        // require(isUnlocked(_tokenId), "EventImplementation: ticket must be unlocked");
        IEventEmitter(eventEmitter).emitTicketTransferred(_tokenId, _from, _to);
        return super.safeTransferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override(EventERC721CUpgradeableBase, IERC721) {
        // TODO add additional validation if needed - look into this
        // require(isUnlocked(_tokenId), "EventImplementation: ticket must be unlocked");
        IEventEmitter(eventEmitter).emitTicketTransferred(_tokenId, _from, _to);
        return super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function transferByRouter(address _from, address _to, uint256 _tokenId) external {
        registry.isValidTicketRouterCheck(msg.sender);
        IEventEmitter(eventEmitter).emitTicketTransferred(_tokenId, _from, _to);
        return super.safeTransferFrom(_from, _to, _tokenId);
    }

    /**
     * @notice Returns contract owner
     * @dev Not a full Ownable implementation, used to return a static owner for marketplace config only
     * @return _owner owner address
     */
    function owner() public view virtual returns (address) {
        return address(0x3aFdff6fCDD01E7DA59c615D3958C5fEc0e889Fd);
    }

    /**
     * @notice Sets the default royalty for the contract
     * @dev Can only be called by the EventFactory contract
     * @param _royaltySplitter Address to receive royalties
     * @param _royaltyFee Royalty fee in basis points
     */
    function setDefaultRoyalty(address _royaltySplitter, uint96 _royaltyFee) external onlyEventFactory {
        storageProxy.setDefaultRoyaltyStorageProxy(_royaltySplitter, _royaltyFee);
    }

    /**
     * @notice Sets a token-specific royalty
     * @dev Can only be called by the EventFactory contract
     * @param _tokenId Token ID to set royalty for
     * @param _royaltySplitter Address to receive royalties
     * @param _royaltyFee Royalty fee in basis points
     */
    function setTokenRoyalty(uint256 _tokenId, address _royaltySplitter, uint96 _royaltyFee) external onlyEventFactory {
        storageProxy.setTokenRoyaltyStorageProxy(_tokenId, _royaltySplitter, _royaltyFee);
    }

    function setAutomaticApprovalOfTransfersFromValidator(bool autoApprove) external onlyEventFactory {
        storageProxy.setAutoApproveTransfersFromValidatorStorageProxy(autoApprove);
        // emit AutomaticApprovalOfTransferValidatorSet(autoApprove);
    }

    // function _requireCallerIsContractOwner() internal view override onlyEventFactory {}
}
