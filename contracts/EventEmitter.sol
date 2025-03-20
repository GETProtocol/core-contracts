// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// solhint-disable-next-line max-line-length
import { IEventEmitter } from "./interfaces/IEventEmitter.sol";
import { IEventImplementation } from "./interfaces/IEventImplementation.sol";
import { IEconomicsFactory } from "./interfaces/IEconomicsFactory.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title EventEmitter Contract
 * @author Open Ticketing Ecosystem
 * @notice Contract responsible for emitting events to the frontend
 */
contract EventEmitter is OwnableUpgradeable, IEventEmitter, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    mapping(address => bool) public isAuthorized;

    // user => eventImplementation => tokenIds (owned)
    mapping(address => mapping(address => EnumerableSet.UintSet)) private _ownedTokenIds;

    mapping(address => EnumerableSet.UintSet) private _eventImplementationToTokenIds;

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "EventEmitter: Not authorized");
        _;
    }

    function __EventEmitter_init(address _owner) public initializer {
        __Context_init();
        __Ownable_init(_owner);
    }

    // View functions for ownership oracle part

    function getTokenIds(address _eventImplementation) external view returns (uint256[] memory) {
        return _eventImplementationToTokenIds[_eventImplementation].values();
    }

    function getTokenIdsLength(address _eventImplementation) external view returns (uint256) {
        return _eventImplementationToTokenIds[_eventImplementation].length();
    }

    function isTokenIdIssuedByEventImplementation(
        address _eventImplementation,
        uint256 _tokenId
    ) external view returns (bool) {
        return _eventImplementationToTokenIds[_eventImplementation].contains(_tokenId);
    }

    function getOwnedTokenIdsOfUser(
        address _account,
        address _eventImplementation
    ) external view returns (uint256[] memory) {
        return _ownedTokenIds[_account][_eventImplementation].values();
    }

    function isTokenIdOwned(
        address _account,
        uint256 _tokenId,
        address _eventImplementation
    ) external view returns (bool) {
        return _ownedTokenIds[_account][_eventImplementation].contains(_tokenId);
    }

    function getOwnedTokenIdsOfUserLength(
        address _account,
        address _eventImplementation
    ) external view returns (uint256) {
        return _ownedTokenIds[_account][_eventImplementation].length();
    }

    // Operational functions for the ownership oracle part

    function mintNewTokenId(uint256 _tokenId, address _to, address _eventImplementation) external onlyAuthorized {
        _addTokenId(_to, _tokenId, _eventImplementation);
        _eventImplementationToTokenIds[_eventImplementation].add(_tokenId);
    }

    function transferTokenId(
        uint256 _tokenId,
        address _from,
        address _to,
        address _eventImplementation
    ) external onlyAuthorized {
        _removeTokenId(_from, _tokenId, _eventImplementation);
        _addTokenId(_to, _tokenId, _eventImplementation);
    }

    function burnTokenId(address _from, uint256 _tokenId, address _eventImplementation) external onlyAuthorized {
        _removeTokenId(_from, _tokenId, _eventImplementation);
        _eventImplementationToTokenIds[_eventImplementation].remove(_tokenId);
    }

    // Internal functions

    function _addTokenId(address _account, uint256 _tokenId, address _eventImplementation) internal {
        _ownedTokenIds[_account][_eventImplementation].add(_tokenId);
    }

    function _removeTokenId(address _account, uint256 _tokenId, address _eventImplementation) internal {
        _ownedTokenIds[_account][_eventImplementation].remove(_tokenId);
    }

    // called by actions processor
    function emitPrimarySale(
        address _eventImplementation,
        IEventImplementation.TicketAction[] memory _ticketActions,
        uint256 _totalFuel,
        uint256 _protocolFuel,
        uint256 _totalFuelUSD,
        uint256 _protocolFuelUSD
    ) external onlyAuthorized {
        emit PrimarySale(
            _eventImplementation,
            _ticketActions,
            _totalFuel,
            _protocolFuel,
            _totalFuelUSD,
            _protocolFuelUSD
        );
    }

    // called by actions processor
    function emitSecondarySale(
        address _eventImplementation,
        IEventImplementation.TicketAction[] memory _ticketActions,
        uint256 _totalFuel,
        uint256 _protocolFuel,
        uint256 _totalFuelUSD,
        uint256 _protocolFuelUSD
    ) external onlyAuthorized {
        emit SecondarySale(
            _eventImplementation,
            _ticketActions,
            _totalFuel,
            _protocolFuel,
            _totalFuelUSD,
            _protocolFuelUSD
        );
    }

    // called by actions processor
    function emitScanned(
        address _eventImplementation,
        IEventImplementation.TicketAction[] memory _ticketActions,
        uint256 _fuelTokens,
        uint256 _fuelTokensProtocol
    ) external onlyAuthorized {
        emit Scanned(_eventImplementation, _ticketActions, _fuelTokens, _fuelTokensProtocol);
    }

    // called by actions processor
    function emitCheckedIn(
        address _eventImplementation,
        IEventImplementation.TicketAction[] memory _ticketActions,
        uint256 _fuelTokens,
        uint256 _fuelTokensProtocol
    ) external onlyAuthorized {
        emit CheckedIn(_eventImplementation, _ticketActions, _fuelTokens, _fuelTokensProtocol);
    }

    // called by actions processor
    function emitInvalidated(
        address _eventImplementation,
        IEventImplementation.TicketAction[] memory _ticketActions,
        uint256 _fuelTokens,
        uint256 _fuelTokensProtocol
    ) external onlyAuthorized {
        emit Invalidated(_eventImplementation, _ticketActions, _fuelTokens, _fuelTokensProtocol);
    }

    // called by actions processor
    function emitClaimed(
        address _eventImplementation,
        IEventImplementation.TicketAction[] memory _ticketActions
    ) external onlyAuthorized {
        emit Claimed(_eventImplementation, _ticketActions);
    }

    // called by actions processor
    function emitTransfered(
        address _eventImplementation,
        IEventImplementation.TicketAction[] memory _ticketActions
    ) external onlyAuthorized {
        emit Transfered(_eventImplementation, _ticketActions);
    }

    // called by event implementation
    function emitEventDataSet(IEventImplementation.EventData memory _eventData) external onlyAuthorized {
        emit EventDataSet(msg.sender, _eventData);
    }

    // Events and functions for the event implementation contract

    // called by event implementation
    function emitTicketTransferred(uint256 _tokenId, address _from, address _to) external onlyAuthorized {
        _removeTokenId(_from, _tokenId, msg.sender);
        _addTokenId(_to, _tokenId, msg.sender);
        emit TicketTransferred(msg.sender, _tokenId, _from, _to);
    }

    // called by event implementation
    function emitDefaultRoyaltySet(address _royaltySplitter, uint96 _royaltyFee) external onlyAuthorized {
        emit DefaultRoyaltySet(msg.sender, _royaltySplitter, _royaltyFee);
    }

    // called by event implementation
    function emitTokenRoyaltySet(
        uint256 _tokenId,
        address _royaltySplitter,
        uint96 _royaltyFee
    ) external onlyAuthorized {
        emit TokenRoyaltySet(msg.sender, _tokenId, _royaltySplitter, _royaltyFee);
    }

    // called by event implementation
    function emitEventDataUpdated(IEventImplementation.EventData memory _eventData) external onlyAuthorized {
        emit EventDataUpdated(msg.sender, _eventData);
    }

    // called by actions processor
    function emitActionErrorLog(
        IEventImplementation.TicketAction memory _ticketActions,
        IEventImplementation.ErrorFlags _errorFlag,
        uint256 _tokenId,
        address _eventAddress,
        uint64 _actionId
    ) external override onlyAuthorized {
        emit ActionErrorLog(_eventAddress, _ticketActions, _errorFlag, _tokenId, _actionId);
    }

    // called by event implementation
    function emitTicketMinted(IEventImplementation.TicketAction memory _ticketAction) external onlyAuthorized {
        _addTokenId(_ticketAction.to, _ticketAction.tokenId, msg.sender);
        _eventImplementationToTokenIds[msg.sender].add(_ticketAction.tokenId);
        emit TicketMinted(msg.sender, _ticketAction);
    }

    // called by event implementation
    function emitTicketBurned(uint256 _tokenId) external onlyAuthorized {
        // address owner_ = IERC721(msg.sender).ownerOf(_tokenId);
        // _removeTokenId(owner_, _tokenId, msg.sender);
        _eventImplementationToTokenIds[msg.sender].remove(_tokenId);
        emit TicketBurned(msg.sender, _tokenId);
    }

    // called by event factory

    function emitEventCreated(uint256 _eventIndex, address _eventImplementationProxy) external onlyAuthorized {
        emit EventCreated(_eventIndex, _eventImplementationProxy);
    }

    // called by router registry
    function emitRouterInUse(address _eventAddress, address _routerAddress) external onlyAuthorized {
        emit RouterInUse(_eventAddress, _routerAddress);
    }

    // called by economics implementation
    function emitOverdraftEnabledStatusSet(bool _shouldEnableOverdraft) external onlyAuthorized {
        emit OverdraftEnabledStatusSet(msg.sender, _shouldEnableOverdraft);
    }

    // called by economics implementation
    function emitToppedUp(uint256 _price, uint256 _amount) external onlyAuthorized {
        emit ToppedUp(msg.sender, _price, _amount);
    }

    // called by economics implementation
    function emitFuelReservedFromTicks(uint256 _usdAmount, uint256 _fuelAmount) external onlyAuthorized {
        emit FuelReservedFromTicks(msg.sender, _usdAmount, _fuelAmount);
    }

    // called by economics implementation
    function emitOverdraftInterestSet(uint256 _interestPerYear) external onlyAuthorized {
        emit OverdraftInterestSet(msg.sender, _interestPerYear);
    }

    // called by payment splitter factory
    function emitPaymentSplitterDeployed(
        address _eventAddress,
        address _paymentSplitter,
        address[] memory _payeesRoyalty,
        uint256[] memory _sharesRoyalty
    ) external onlyAuthorized {
        emit PaymentSplitterDeployed(_eventAddress, _paymentSplitter, _payeesRoyalty, _sharesRoyalty);
    }

    // called by payment splitter initializable
    function emitERC20FundsReleased(
        address _eventAddress,
        address _token,
        uint256[] memory _amounts,
        address[] memory _payees
    ) external onlyAuthorized {
        emit ERC20FundsReleased(_eventAddress, _token, _amounts, _payees);
    }

    function emitNativeFundsReleased(
        address _eventAddress,
        uint256[] memory _amounts,
        address[] memory _payees
    ) external onlyAuthorized {
        emit NativeFundsReleased(_eventAddress, _amounts, _payees);
    }

    function emitPayeesSet(address _eventAddress, address[] memory _payeesArray) external onlyAuthorized {
        emit PayeesSet(_eventAddress, _payeesArray);
    }

    // function emitPausedSet(address _eventAddress, bool _isPaused) external onlyAuthorized {
    //     emit PausedSet(_eventAddress, _isPaused);
    // }

    function emitPaymentReceivedNative(address _eventAddress, address _from, uint256 _amount) external onlyAuthorized {
        emit PaymentReceivedNative(_eventAddress, _from, _amount);
    }

    function emitPayeeAdded(address _eventAddress, address _account, uint256 _shares) external onlyAuthorized {
        emit PayeeAdded(_eventAddress, _account, _shares);
    }

    function emitERC20PaymentReleasedSingle(
        address _eventAddress,
        address _token,
        address _to,
        uint256 _amount
    ) external onlyAuthorized {
        emit ERC20PaymentReleasedSingle(_eventAddress, _token, _to, _amount);
    }

    // Configuration functions for the event emitter

    function returnIsAuthorized(address _address) external view override returns (bool) {
        return isAuthorized[_address];
    }

    function authorize(address _address) external override onlyOwner {
        isAuthorized[_address] = true;
        emit Authorized(_address);
    }

    function authorizeByFactory(address _address) external override onlyAuthorized {
        isAuthorized[_address] = true;
        emit Authorized(_address);
    }

    function unauthorize(address _address) external override onlyOwner {
        isAuthorized[_address] = false;
        emit Unauthorized(_address);
    }

    /**
     * @notice An internal function to authorize a contract upgrade
     * @dev The function is a requirement for OpenZeppelin's UUPS upgradeable contracts
     *
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
