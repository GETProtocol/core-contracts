// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IEventImplementation } from "../interfaces/IEventImplementation.sol";

library EventERC721CUpgradeableBaseStorage {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    uint96 internal constant ROYALTY_FEE_DENOMINATOR = 10000;

    /// @custom:storage-location erc7201:event.erc721c.upgradeable.base.storage
    bytes32 public constant EVENT_ERC721C_UPGRADEABLE_BASE_STORAGE_POSITION =
        keccak256("event.erc721c.upgradeable.base.storage");

    struct Data {
        // Token name
        string name;
        // Token symbol
        string symbol;
        // Token-specific data struct
        mapping(uint256 => IEventImplementation.TokenData) tokenData;
        // Address-specific data struct
        mapping(address => IEventImplementation.AddressData) addressData;
        // Mapping from token ID to approved address
        mapping(uint256 => address) tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
        // If true, the collection's transfer validator is automatically approved to transfer holder's tokens.
        bool autoApproveTransfersFromValidator;
        address transferValidator;
        IEventImplementation.EventData eventData;
        IEventImplementation.EventFinancing eventFinancing;
        address defaultRoyaltyReceiver;
        uint96 defaultRoyaltyFraction;
        RoyaltyInfo defaultRoyaltyInfo;
        mapping(uint256 => RoyaltyInfo) tokenRoyaltyInfo;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = EVENT_ERC721C_UPGRADEABLE_BASE_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}
