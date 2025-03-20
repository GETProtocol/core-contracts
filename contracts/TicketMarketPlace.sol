// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { IPaymentSplitterInitializable } from "./interfaces/IPaymentSplitterInitializable.sol";
import { ITicketMarketPlace } from "./interfaces/ITicketMarketPlace.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IEventImplementation } from "./interfaces/IEventImplementation.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

/**
 * @title TicketMarketPlace
 * @dev This contract implements a decentralized marketplace for NFT tickets.
 * It allows users to create, cancel, and fulfill signed orders for ticket sales.
 * The contract also handles royalty payments according to the ERC2981 standard.
 */
contract TicketMarketPlace is ITicketMarketPlace, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using ECDSA for bytes32;

    // Mapping to store signed orders by their hash
    mapping(bytes32 => SignedOrder) public signedOrders;
    // Mapping to track cancelled or fulfilled orders
    mapping(bytes32 => bool) public cancelledOrFulfilled;

    mapping(address => bool) public relayerOfEngine;

    // New mappings for order index
    mapping(uint256 => bytes32) public orderIndexToHash;
    mapping(bytes32 => uint256) public orderHashToIndex;
    uint256 public orderIndex;

    // The ERC20 token used for all payments in the marketplace
    IERC20 public immutable stableCoinToken;
    IERC20Permit public immutable stableCoinPermit;

    // The registry contract
    IRegistry public immutable registry;

    /**
     * @dev Constructor to set the stable coin token address
     * @param _stableCoinToken The address of the ERC20 token to be used for payments
     */
    constructor(address _stableCoinToken, address _registry, address initialOwner) Ownable(initialOwner) {
        stableCoinToken = IERC20(_stableCoinToken);
        stableCoinPermit = IERC20Permit(_stableCoinToken);
        registry = IRegistry(_registry);
        orderIndex = 0;
    }

    // Modifiers
    modifier onlyRelayerOfEngine() {
        require(relayerOfEngine[msg.sender], "Not a relayer of engine");
        _;
    }

    // Functions

    /**
     * @dev Creates a new signed order for selling a ticket
     * @param _eventImplementation Address of the NFT contract
     * @param _tokenId ID of the ticket (NFT) being sold
     * @param _price Price of the ticket in stable coin tokens
     * @param _expirationTime Timestamp when the order expires
     * @param _signature Signature of the seller to validate the order
     */
    function createSignedOrderByEngine(
        address _eventImplementation,
        uint256 _tokenId,
        uint256 _price,
        uint256 _expirationTime,
        address _seller,
        bytes memory _signature
    ) external onlyRelayerOfEngine returns (uint256) {
        return _createSignedOrder(_eventImplementation, _tokenId, _price, _expirationTime, _seller, _signature);
    }

    /**
     * @dev Creates a new signed order for selling a ticket
     * @dev This function is called by the seller/owner of the ticket
     * @param _eventImplementation Address of the NFT contract
     * @param _tokenId ID of the ticket (NFT) being sold
     * @param _price Price of the ticket in stable coin tokens
     * @param _expirationTime Timestamp when the order expires
     * @param _signature Signature of the seller to validate the order
     */
    function createSignedOrderBySeller(
        address _eventImplementation,
        uint256 _tokenId,
        uint256 _price,
        uint256 _expirationTime,
        bytes memory _signature
    ) external returns (uint256) {
        return _createSignedOrder(_eventImplementation, _tokenId, _price, _expirationTime, msg.sender, _signature);
    }

    /**
     * @dev Creates a new signed order for selling a ticket from a bytes object
     * @param _orderData The bytes object containing the order data
     */
    function createSignedOrderFromBytes(bytes memory _orderData) external returns (uint256) {
        (
            address _eventImplementation,
            uint256 _tokenId,
            uint256 _price,
            uint256 _expirationTime,
            address _seller,
            bytes memory _signature
        ) = abi.decode(_orderData, (address, uint256, uint256, uint256, address, bytes));

        return _createSignedOrder(_eventImplementation, _tokenId, _price, _expirationTime, _seller, _signature);
    }

    /**
     * @dev Cancels an existing order
     * @param _orderHash The hash of the order to be cancelled
     */
    function cancelOrderByEngine(bytes32 _orderHash, address _seller) external onlyRelayerOfEngine {
        _cancelOrder(_orderHash, _seller);
    }

    /**
     * @dev Cancels an existing order
     * @param _orderHash The hash of the order to be cancelled
     */
    function cancelOrderBySeller(bytes32 _orderHash) external {
        _cancelOrder(_orderHash, msg.sender);
    }

    /**
     * @dev Fulfills an existing order by purchasing the ticket
     * @param _orderHash The hash of the order to be fulfilled
     */
    function fulfillOrderByEngine(bytes32 _orderHash, address _buyer) external onlyRelayerOfEngine {
        _fulfillOrder(_orderHash, _buyer);
    }

    /**
     * @dev Fulfills an existing order by purchasing the ticket
     * @param _orderHash The hash of the order to be fulfilled
     */
    function fulfillOrderByBuyer(bytes32 _orderHash) external {
        _fulfillOrder(_orderHash, msg.sender);
    }

    /**
     * @dev Fulfills an existing order by purchasing the ticket, using permit for approval
     * @param _orderHash The hash of the order to be fulfilled
     * @param _deadline The deadline for the permit
     * @param _v The v part of the signature
     * @param _r The r part of the signature
     * @param _s The s part of the signature
     */
    function fulfillOrderByBuyerWithPermit(
        bytes32 _orderHash,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        SignedOrder storage order = signedOrders[_orderHash];

        // Use permit to approve tokens
        stableCoinPermit.permit(msg.sender, address(this), order.price, _deadline, _v, _r, _s);

        _fulfillOrder(_orderHash, msg.sender);
        emit OrderFulfilledWithPermit(_orderHash, orderHashToIndex[_orderHash], msg.sender);
    }

    /**
     * @dev Fulfills an existing order by purchasing the ticket, using permit for approval (called by engine)
     * @param _orderHash The hash of the order to be fulfilled
     * @param _buyer The address of the buyer
     * @param _deadline The deadline for the permit
     * @param _v The v part of the signature
     * @param _r The r part of the signature
     * @param _s The s part of the signature
     */
    function fulfillOrderByEngineWithPermit(
        bytes32 _orderHash,
        address _buyer,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external onlyRelayerOfEngine {
        SignedOrder storage order = signedOrders[_orderHash];

        // Use permit to approve tokens
        stableCoinPermit.permit(_buyer, address(this), order.price, _deadline, _v, _r, _s);

        _fulfillOrder(_orderHash, _buyer);
        emit OrderFulfilledByEngineWithPermit(_orderHash, orderHashToIndex[_orderHash], _buyer);
    }

    // Internal functions

    /**
     * @dev Creates a new signed order for selling a ticket
     * @param _eventImplementation Address of the NFT contract
     * @param _tokenId ID of the ticket (NFT) being sold
     * @param _price Price of the ticket in stable coin tokens
     * @param _expirationTime Timestamp when the order expires
     * @param _signature Signature of the seller to validate the order
     */
    function _createSignedOrder(
        address _eventImplementation,
        uint256 _tokenId,
        uint256 _price,
        uint256 _expirationTime,
        address _seller,
        bytes memory _signature
    ) internal returns (uint256) {
        // Ensure the caller is the owner of the ticket
        require(IERC721(_eventImplementation).ownerOf(_tokenId) == _seller, "Not the owner of the ticket");

        // Create a new SignedOrder struct with the provided parameters
        SignedOrder memory order = SignedOrder({
            seller: _seller,
            eventImplementation: _eventImplementation,
            tokenId: _tokenId,
            price: _price,
            expirationTime: _expirationTime,
            signature: _signature
        });

        // Hash the order and verify the signature
        bytes32 orderHash = _hashOrder(order);
        require(_verifySignature(orderHash, _signature, _seller), "Invalid signature");

        // Store the order and emit an event
        signedOrders[orderHash] = order;

        // Increment order index and store mappings
        orderIndex++;
        orderIndexToHash[orderIndex] = orderHash;
        orderHashToIndex[orderHash] = orderIndex;

        emit OrderCreated(orderHash, order, orderIndex);
        return orderIndex;
    }

    /**
     * @dev Cancels an existing order
     * @param _orderHash The hash of the order to be cancelled
     */
    function _cancelOrder(bytes32 _orderHash, address _seller) internal {
        SignedOrder storage order = signedOrders[_orderHash];
        // Ensure the caller is the seller of the order
        require(order.seller == _seller, "Not the seller");
        // Ensure the order hasn't been cancelled or fulfilled already
        require(!cancelledOrFulfilled[_orderHash], "Order already cancelled or fulfilled");

        // Mark the order as cancelled and emit an event
        cancelledOrFulfilled[_orderHash] = true;
        emit OrderCancelled(_orderHash, orderHashToIndex[_orderHash]);
    }

    function _fulfillOrder(bytes32 _orderHash, address _buyer) internal {
        SignedOrder storage order = signedOrders[_orderHash];
        // Ensure the order hasn't been cancelled or fulfilled already
        require(!cancelledOrFulfilled[_orderHash], "Order already cancelled or fulfilled");
        // Ensure the order hasn't expired
        require(block.timestamp <= order.expirationTime, "Order expired");

        // check if the seller is still the owner of the ticket
        require(IERC721(order.eventImplementation).ownerOf(order.tokenId) == order.seller, "Seller is not the owner");

        // Check if the NFT contract supports ERC2981 for royalties
        IERC2981 nftContract = IERC2981(order.eventImplementation);
        (address royaltyReceiver, uint256 royaltyAmount) = nftContract.royaltyInfo(order.tokenId, order.price);

        // Calculate the amount that goes to the seller (price minus royalty)
        uint256 sellerAmount = order.price - royaltyAmount;

        // Transfer the payment to the seller
        require(stableCoinToken.transferFrom(_buyer, order.seller, sellerAmount), "Payment to seller failed");

        // Transfer the royalty if applicable
        if (royaltyAmount > 0) {
            require(stableCoinToken.transferFrom(_buyer, royaltyReceiver, royaltyAmount), "Royalty payment failed");
        }

        // Transfer the NFT to the buyer
        IEventImplementation(order.eventImplementation).transferByRouter(order.seller, _buyer, order.tokenId);

        // Mark the order as fulfilled and emit events
        cancelledOrFulfilled[_orderHash] = true;

        emit OrderFulfilled(_orderHash, orderHashToIndex[_orderHash], _buyer);

        if (royaltyAmount > 0) {
            emit RoyaltyPaid(
                order.eventImplementation,
                order.tokenId,
                royaltyReceiver,
                royaltyAmount,
                orderHashToIndex[_orderHash]
            );
        }
    }

    /**
     * @dev Hashes an order struct to create a unique identifier
     * @param _order The SignedOrder struct to hash
     * @return bytes32 The resulting hash of the order
     */
    function _hashOrder(SignedOrder memory _order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _order.seller,
                    _order.eventImplementation,
                    _order.tokenId,
                    _order.price,
                    _order.expirationTime
                )
            );
    }

    /**
     * @dev Verifies the signature of an order
     * @param _hash The hash of the order
     * @param _signature The signature to verify
     * @param _signer The expected signer of the order
     * @return bool True if the signature is valid, false otherwise
     */
    function _verifySignature(bytes32 _hash, bytes memory _signature, address _signer) internal pure returns (bool) {
        // Manual prefix
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
        return ECDSA.recover(ethSignedHash, _signature) == _signer;
    }

    // Configuration functions
    function setRelayerOfEngine(address _engine, bool _isRelayer) external onlyOwner {
        relayerOfEngine[_engine] = _isRelayer;
        emit RelayerOfEngineSet(_engine, _isRelayer);
    }
}
