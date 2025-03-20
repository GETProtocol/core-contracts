// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IEventImplementation is IERC721 {
    enum TicketFlags {
        SCANNED, // 0
        CHECKED_IN, // 1
        INVALIDATED, // 2
        UNLOCKED // 3
    }

    enum ErrorFlags {
        ALREADY_INVALIDATED, // 0
        NON_EXISTING, // 1
        ALREADY_CHECKED_IN, // 2
        EVENT_ENDED, // 3
        INVENTORY_BLOCKED_PRIMARY, // 4
        INVENTORY_BLOCKED_SECONDARY, // 5
        INVENTORY_BLOCKED_SCAN, // 6
        INVENTORY_BLOCKED_CLAIM, // 7
        ALREADY_EXISTING, // 8
        MINT_TO_ZERO_ADDRESS // 9
    }
    struct TokenData {
        address owner;
        uint40 basePrice;
        uint8 booleanFlags;
    }

    struct AddressData {
        // uint64 more than enough
        uint64 balance;
    }

    struct EventData {
        uint32 index;
        uint64 startTime;
        uint64 endTime;
        int32 latitude;
        int32 longitude;
        string currency;
        string name;
        string shopUrl;
        string imageUrl;
    }

    struct TicketAction {
        uint256 tokenId;
        bytes32 externalId; // sha256 hashed, emitted in event only.
        address to;
        uint64 orderTime;
        uint40 basePrice;
    }

    struct EventFinancing {
        uint64 palletIndex;
        address bondCouncil;
        bool inventoryRegistered;
        bool financingActive;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }

    event EventDataSet(EventData eventData);
    event EventDataUpdated(EventData eventData);

    event UpdateFinancing(EventFinancing financing);

    function batchActions(
        TicketAction[] calldata _ticketActions,
        uint8[] calldata _actionCounts,
        uint64[] calldata _actionIds
    ) external;

    function batchActionsFromFactory(
        TicketAction[] calldata _ticketActions,
        uint8[] calldata _actionCounts,
        uint64[] calldata _actionIds,
        address _msgSender
    ) external;

    function mint(TicketAction calldata _ticketAction) external;

    function burn(uint256 _tokenId) external;

    function setEventData(EventData memory _eventData) external;

    function setFinancing(EventFinancing memory _financing) external;

    function owner() external view returns (address);

    function setTokenRoyaltyDefault(address _royaltyReceiver, uint96 _feeDenominator) external;

    function deleteRoyaltyInfoDefault() external;

    function deleteRoyaltyException(uint256 _tokenId) external;

    function setDefaultRoyalty(address royaltySplitter, uint96 royaltyFeeNumerator) external;

    function setTokenRoyalty(uint256 tokenId, address royaltySplitter, uint96 royaltyFeeNumerator) external;

    function transferByRouter(address _from, address _to, uint256 _tokenId) external;

    function transfer(address _from, address _to, uint256 _tokenId) external;
}
