// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IEventImplementation } from "./IEventImplementation.sol";

interface IEventERC721CStorageProxy {
    function initContract(string memory _name, string memory _symbol) external;
    function initializeStorageProxy(address _registry, address _actionProcessor) external;

    function setNameStorageProxy(string memory _name) external;
    function setSymbolStorageProxy(string memory _symbol) external;
    function setTokenDataStorageProxy(uint256 _tokenId, IEventImplementation.TokenData memory _tokenData) external;
    function setAddressDataStorageProxy(
        address _address,
        IEventImplementation.AddressData memory _addressData
    ) external;
    function setTokenApprovalStorageProxy(uint256 _tokenId, address _approved) external;
    function setOperatorApprovalStorageProxy(address _owner, address _operator, bool _approved) external;
    function setAutoApproveTransfersFromValidatorStorageProxy(bool _autoApprove) external;
    function setEventFinancingStorageProxy(IEventImplementation.EventFinancing memory _eventFinancing) external;
    function setScannedFlagStorageProxy(uint256 _tokenId, bool _scanned) external;
    function setCheckedInFlagStorageProxy(uint256 _tokenId, bool _checkedIn) external;
    function setInvalidatedFlagStorageProxy(uint256 _tokenId, bool _invalidated) external;
    function setUnlockedFlagStorageProxy(uint256 _tokenId, bool _unlocked) external;
    function setEventDataStorageProxy(IEventImplementation.EventData calldata _eventData) external;
    function updateEventDataStorageProxy(IEventImplementation.EventData calldata _eventData) external;
    function setFinancingStorageProxy(IEventImplementation.EventFinancing calldata _financing) external;
    function setDefaultRoyaltyStorageProxy(address _receiver, uint96 _royaltyFraction) external;
    function setTokenRoyaltyStorageProxy(uint256 _tokenId, address _receiver, uint96 _royaltyFraction) external;
    function mintStorageProxy(IEventImplementation.TicketAction calldata _ticketAction) external;
    function burnStorageProxy(uint256 _tokenId, address _from) external;
    function setTokenRoyaltyDefaultStorageProxy(address _receiver, uint96 _feeNominator) external;
    function setExceptionTokenRoyaltyStorageProxy(address _receiver, uint256 _tokenId, uint96 _feeNominator) external;
    function deleteRoyaltyInfoDefaultStorageProxy() external;
    function deleteRoyaltyExceptionStorageProxy(uint256 _tokenId) external;
    function setAuthorizedStorageProxy(address _address, bool _authorized) external;
    function burnTokenDataStorageProxy(uint256 _tokenId) external;
    function manageTokenTransferStorageProxy(uint256 _tokenId, address _from, address _to) external;
    // view functions
    function isScannedStorageProxy(uint256 _tokenId) external view returns (bool);
    function isCheckedInStorageProxy(uint256 _tokenId) external view returns (bool);
    function isInvalidatedStorageProxy(uint256 _tokenId) external view returns (bool);
    function isUnlockedStorageProxy(uint256 _tokenId) external view returns (bool);
    function isEventEndedStorageProxy() external view returns (bool);
    function isPrimaryBlockedStorageProxy() external view returns (bool);
    function isSecondaryBlockedStorageProxy() external view returns (bool);
    function isScanBlockedStorageProxy() external view returns (bool);
    function isClaimBlockedStorageProxy() external view returns (bool);
    function isExistingStorageProxy(uint256 _tokenId) external view returns (bool);
    function getTokenDataStorageProxy(uint256 _tokenId) external view returns (IEventImplementation.TokenData memory);
    function getAddressDataStorageProxy(
        address _address
    ) external view returns (IEventImplementation.AddressData memory);
    function getTokenApprovalStorageProxy(uint256 _tokenId) external view returns (address);
    function getOperatorApprovalStorageProxy(address _owner, address _operator) external view returns (bool);
    function getNameStorageProxy() external view returns (string memory);
    function getSymbolStorageProxy() external view returns (string memory);
    function getEventDataStorageProxy() external view returns (IEventImplementation.EventData memory);
    function getEventFinancingStorageProxy() external view returns (IEventImplementation.EventFinancing memory);
    function getRoyaltyInfoStorageProxy(uint256 _tokenId) external view returns (address, uint96);
    function getAutoApproveTransfersFromValidatorStorageProxy() external view returns (bool);
    function getTransferValidatorStorageProxy() external view returns (address);
    function getActionProcessorStorageProxy() external view returns (address);
}
