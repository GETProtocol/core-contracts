// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITicketMarketPlace {
    /**
     * @dev Struct to represent a signed order for selling a ticket
     */
    struct SignedOrder {
        address seller; // Address of the ticket seller
        address eventImplementation; // Address of the NFT contract
        uint256 tokenId; // ID of the ticket (NFT) being sold
        uint256 price; // Price of the ticket in stable coin tokens
        uint256 expirationTime; // Timestamp when the order expires
        bytes signature; // Signature of the seller to validate the order
    }

    // Events
    event OrderCreated(bytes32 indexed orderHash, SignedOrder order, uint256 indexed orderIndex);
    event OrderCancelled(bytes32 indexed orderHash, uint256 indexed orderIndex);
    event OrderFulfilled(bytes32 indexed orderHash, uint256 indexed orderIndex, address buyer);
    event RoyaltyPaid(
        address indexed nftContract,
        uint256 indexed tokenId,
        address royaltyReceiver,
        uint256 royaltyAmount,
        uint256 indexed orderIndex
    );
    event RelayerOfEngineSet(address indexed engine, bool isRelayer);

    // Add these new functions and events to the interface
    function createSignedOrderByEngine(
        address _eventImplementation,
        uint256 _tokenId,
        uint256 _price,
        uint256 _expirationTime,
        address _seller,
        bytes memory _signature
    ) external returns (uint256);

    function createSignedOrderFromBytes(bytes memory _orderData) external returns (uint256);

    function fulfillOrderByBuyerWithPermit(
        bytes32 _orderHash,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function fulfillOrderByEngineWithPermit(
        bytes32 _orderHash,
        address _buyer,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    event OrderFulfilledWithPermit(bytes32 indexed orderHash, uint256 indexed orderIndex, address buyer);
    event OrderFulfilledByEngineWithPermit(bytes32 indexed orderHash, uint256 indexed orderIndex, address buyer);
}
