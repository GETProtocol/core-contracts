// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./abstract/EventERC721CUpgradeableBaseStorage.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IEventImplementation } from "./interfaces/IEventImplementation.sol";

contract EventERC721CStorageProxy is Initializable {
    using EventERC721CUpgradeableBaseStorage for EventERC721CUpgradeableBaseStorage.Data;
    IRegistry public registry;
    address public actionProcessor;

    mapping(address => bool) public isAuthorized;

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "Only authorized contracts can call this function xoxo1");
        _;
    }

    function setAuthorizedStorageProxy(address _address, bool _authorized) external onlyAuthorized {
        isAuthorized[_address] = _authorized;
    }

    function initContract(string memory _name, string memory _symbol) external {
        require(bytes(EventERC721CUpgradeableBaseStorage.data().name).length == 0, "Contract already initialized");
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.name = _name;
        s.symbol = _symbol;
        isAuthorized[msg.sender] = true;
    }

    function initializeStorageProxy(address _registry, address _actionProcessor) public initializer {
        registry = IRegistry(_registry);
        actionProcessor = _actionProcessor;
        isAuthorized[msg.sender] = true;
        isAuthorized[_actionProcessor] = true;
        isAuthorized[_registry] = true;
    }

    function setNameStorageProxy(string memory _name) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.name = _name;
    }

    function setSymbolStorageProxy(string memory _symbol) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.symbol = _symbol;
    }

    function setTokenDataStorageProxy(
        uint256 _tokenId,
        IEventImplementation.TokenData memory _tokenData
    ) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.tokenData[_tokenId] = _tokenData;
    }

    function setAddressDataStorageProxy(
        address _address,
        IEventImplementation.AddressData memory _addressData
    ) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.addressData[_address] = _addressData;
    }

    function setTokenApprovalStorageProxy(uint256 _tokenId, address _approved) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.tokenApprovals[_tokenId] = _approved;
    }

    function setOperatorApprovalStorageProxy(
        address _owner,
        address _operator,
        bool _approved
    ) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.operatorApprovals[_owner][_operator] = _approved;
    }

    function setAutoApproveTransfersFromValidatorStorageProxy(bool _autoApprove) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.autoApproveTransfersFromValidator = _autoApprove;
    }

    function setEventFinancingStorageProxy(
        IEventImplementation.EventFinancing memory _eventFinancing
    ) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.eventFinancing = _eventFinancing;
    }

    function setScannedFlagStorageProxy(uint256 _tokenId, bool _scanned) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.tokenData[_tokenId].booleanFlags = _setBoolean(
            s.tokenData[_tokenId].booleanFlags,
            uint8(IEventImplementation.TicketFlags.SCANNED),
            _scanned
        );
    }

    function setCheckedInFlagStorageProxy(uint256 _tokenId, bool _checkedIn) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.tokenData[_tokenId].booleanFlags = _setBoolean(
            s.tokenData[_tokenId].booleanFlags,
            uint8(IEventImplementation.TicketFlags.CHECKED_IN),
            _checkedIn
        );
    }

    function setInvalidatedFlagStorageProxy(uint256 _tokenId, bool _invalidated) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.tokenData[_tokenId].booleanFlags = _setBoolean(
            s.tokenData[_tokenId].booleanFlags,
            uint8(IEventImplementation.TicketFlags.INVALIDATED),
            _invalidated
        );
    }

    function setUnlockedFlagStorageProxy(uint256 _tokenId, bool _unlocked) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.tokenData[_tokenId].booleanFlags = _setBoolean(
            s.tokenData[_tokenId].booleanFlags,
            uint8(IEventImplementation.TicketFlags.UNLOCKED),
            _unlocked
        );
    }

    function setEventDataStorageProxy(IEventImplementation.EventData calldata _eventData) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.eventData = _eventData;
    }

    function updateEventDataStorageProxy(IEventImplementation.EventData calldata _eventData) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.eventData = _eventData;
    }

    function setFinancingStorageProxy(IEventImplementation.EventFinancing calldata _financing) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.eventFinancing = _financing;
    }

    function mintStorageProxy(IEventImplementation.TicketAction calldata _ticketAction) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();

        s.tokenData[_ticketAction.tokenId] = IEventImplementation.TokenData(
            _ticketAction.to,
            _ticketAction.basePrice,
            0
        );
        s.addressData[_ticketAction.to].balance += 1;
    }

    function burnStorageProxy(uint256 _tokenId, address _from) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.tokenData[_tokenId] = IEventImplementation.TokenData(address(0), 0, 0);
        s.addressData[_from].balance -= 1;
    }

    function returnEventDataStorageProxy() external view returns (IEventImplementation.EventData memory) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.eventData;
    }

    function _setBoolean(uint8 _packedBools, uint8 _boolNumber, bool _value) internal pure returns (uint8) {
        unchecked {
            return _value ? _packedBools | (uint8(1) << _boolNumber) : _packedBools & ~(uint8(1) << _boolNumber);
        }
    }

    function burnTokenDataStorageProxy(uint256 _tokenId) external onlyAuthorized {
        address owner = EventERC721CUpgradeableBaseStorage.data().tokenData[_tokenId].owner;
        // -1 on balance
        EventERC721CUpgradeableBaseStorage.data().addressData[owner].balance -= 1;
        // +1 on zero address balance
        EventERC721CUpgradeableBaseStorage.data().addressData[address(0)].balance += 1;
        // set owner to zero address
        EventERC721CUpgradeableBaseStorage.data().tokenData[_tokenId].owner = address(0);
    }

    function _getBoolean(uint8 _packedBools, uint8 _boolNumber) internal pure returns (bool) {
        uint8 _flag = (_packedBools >> _boolNumber) & uint8(1);
        return (_flag == 1 ? true : false);
    }

    function isScannedStorageProxy(uint256 _tokenId) public view returns (bool) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return _getBoolean(s.tokenData[_tokenId].booleanFlags, uint8(IEventImplementation.TicketFlags.SCANNED));
    }

    function isCheckedInStorageProxy(uint256 _tokenId) public view returns (bool) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return _getBoolean(s.tokenData[_tokenId].booleanFlags, uint8(IEventImplementation.TicketFlags.CHECKED_IN));
    }

    function isInvalidatedStorageProxy(uint256 _tokenId) public view returns (bool) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return _getBoolean(s.tokenData[_tokenId].booleanFlags, uint8(IEventImplementation.TicketFlags.INVALIDATED));
    }

    function isUnlockedStorageProxy(uint256 _tokenId) public view returns (bool) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        IEventImplementation.EventData memory eventData = s.eventData;
        bool _isPastEndTime = (eventData.endTime + 24 hours) <= block.timestamp;
        bool _isZeroEndTime = eventData.endTime == 0;
        return
            _getBoolean(s.tokenData[_tokenId].booleanFlags, uint8(IEventImplementation.TicketFlags.UNLOCKED)) ||
            (_isPastEndTime && !_isZeroEndTime);
    }

    function isEventEnded() public view returns (bool _status) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        IEventImplementation.EventData memory eventData = s.eventData;
        bool _isPastEndTime = (eventData.endTime + 24 hours) <= block.timestamp;
        bool _isZeroEndTime = eventData.endTime == 0;
        return _isPastEndTime && !_isZeroEndTime;
    }

    function isPrimaryBlockedStorageProxy() public view returns (bool _status) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.eventFinancing.primaryBlocked;
    }

    function isSecondaryBlockedStorageProxy() public view returns (bool _status) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.eventFinancing.secondaryBlocked;
    }

    function isExistingStorageProxy(uint256 _tokenId) public view returns (bool _status) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.tokenData[_tokenId].owner != address(0);
    }

    function isScanBlockedStorageProxy() public view returns (bool _status) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.eventFinancing.scanBlocked;
    }

    function isClaimBlockedStorageProxy() public view returns (bool _status) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.eventFinancing.claimBlocked;
    }

    // Royalty functions

    function setDefaultRoyaltyStorageProxy(address _receiver, uint96 _royaltyFraction) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.defaultRoyaltyInfo = EventERC721CUpgradeableBaseStorage.RoyaltyInfo(_receiver, _royaltyFraction);
    }

    function setTokenRoyaltyStorageProxy(
        uint256 _tokenId,
        address _receiver,
        uint96 _royaltyFraction
    ) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.tokenRoyaltyInfo[_tokenId] = EventERC721CUpgradeableBaseStorage.RoyaltyInfo(_receiver, _royaltyFraction);
    }

    function setTokenRoyaltyDefaultStorageProxy(address _receiver, uint96 _feeNominator) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.defaultRoyaltyInfo = EventERC721CUpgradeableBaseStorage.RoyaltyInfo(_receiver, _feeNominator);
    }

    function setExceptionTokenRoyaltyStorageProxy(
        address _receiver,
        uint256 _tokenId,
        uint96 _feeNominator
    ) external onlyAuthorized {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        s.tokenRoyaltyInfo[_tokenId] = EventERC721CUpgradeableBaseStorage.RoyaltyInfo(_receiver, _feeNominator);
    }

    function getRoyaltyInfoStorageProxy(uint256 _tokenId) external view returns (address, uint96) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        EventERC721CUpgradeableBaseStorage.RoyaltyInfo memory royalty = s.tokenRoyaltyInfo[_tokenId];
        if (royalty.receiver == address(0)) {
            royalty = s.defaultRoyaltyInfo;
        }
        return (royalty.receiver, royalty.royaltyFraction);
    }

    // Getter functions

    function getNameStorageProxy() external view returns (string memory) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.name;
    }

    function getSymbolStorageProxy() external view returns (string memory) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.symbol;
    }

    function getTokenDataStorageProxy(uint256 _tokenId) external view returns (IEventImplementation.TokenData memory) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.tokenData[_tokenId];
    }

    function manageTokenTransferStorageProxy(uint256 _tokenId, address _from, address _to) external onlyAuthorized {
        // check if the token exists
        if (EventERC721CUpgradeableBaseStorage.data().tokenData[_tokenId].owner == address(0)) {
            revert("Token does not exist");
        }
        // lower the balance of _from
        EventERC721CUpgradeableBaseStorage.data().addressData[_from].balance -= 1;
        // increase the balance of _to
        EventERC721CUpgradeableBaseStorage.data().addressData[_to].balance += 1;
        // set the owner of the token to _to
        EventERC721CUpgradeableBaseStorage.data().tokenData[_tokenId].owner = _to;
    }

    function getAddressDataStorageProxy(
        address _address
    ) external view returns (IEventImplementation.AddressData memory) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.addressData[_address];
    }

    function getTokenApprovalStorageProxy(uint256 _tokenId) external view returns (address) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.tokenApprovals[_tokenId];
    }

    function getOperatorApprovalStorageProxy(address _owner, address _operator) external view returns (bool) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.operatorApprovals[_owner][_operator];
    }

    function getAutoApproveTransfersFromValidatorStorageProxy() external view returns (bool) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.autoApproveTransfersFromValidator;
    }

    function getEventDataStorageProxy() external view returns (IEventImplementation.EventData memory) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.eventData;
    }

    function getEventFinancingStorageProxy() external view returns (IEventImplementation.EventFinancing memory) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.eventFinancing;
    }

    function getTransferValidatorStorageProxy() external view returns (address) {
        EventERC721CUpgradeableBaseStorage.Data storage s = EventERC721CUpgradeableBaseStorage.data();
        return s.transferValidator;
    }

    function getActionProcessorStorageProxy() external view returns (address) {
        return address(actionProcessor);
    }
}
