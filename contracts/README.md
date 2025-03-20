# Documentation TicketMarketPlace.sol

## Overview

The TicketMarketPlace contract is a decentralized marketplace for NFT tickets, designed to facilitate secure and efficient ticket sales. This smart contract provides a robust platform for creating, managing, and fulfilling ticket sale orders, with built-in support for royalties and gasless transactions.

## Key Features

1. **Decentralized Ticket Sales**: Enables peer-to-peer ticket trading without intermediaries.
2. **Signed Orders**: Utilizes off-chain signed orders for gas-efficient listings and enhanced flexibility.
3. **Multiple Interaction Methods**: Supports direct interactions from buyers/sellers and relayer-assisted transactions.
4. **Royalty Support**: Automatically handles royalty payments to ticket creators using the ERC2981 standard.
5. **Stable Coin Integration**: Uses ERC20 stable coins for all financial transactions, reducing volatility risks.
6. **Gasless Transactions**: Implements ERC20 permit functionality for gasless approvals and transactions.
7. **Order Management**: Provides functions to create, cancel, and fulfill ticket sale orders.
8. **Security Measures**: Includes signature verification and ownership checks to ensure transaction integrity.

## Capabilities

- Create signed sell orders for NFT tickets (by sellers or through relayers)
- Cancel existing sell orders (by sellers or through relayers)
- Fulfill (buy) existing sell orders (by buyers or through relayers)
- Automatic royalty distribution to original creators
- Support for both on-chain and off-chain order management
- Integration with ERC721 for NFT ticket representation
- Flexible pricing in stable coins
- Order expiration functionality for time-limited listings

This marketplace contract serves as a comprehensive solution for event organizers, ticket sellers, and buyers, providing a secure, efficient, and flexible platform for NFT ticket trading.

## TicketMarketPlace.sol

The `TicketMarketPlace.sol` contract implements a decentralized marketplace for NFT tickets. It allows users to create, cancel, and fulfill signed orders for ticket sales. The contract also handles royalty payments according to the ERC2981 standard.

### Key Concept: Signed Orders

The marketplace operates on the concept of signed orders. When a ticket owner wants to sell their ticket, they create an order off-chain and sign it with their private key. This signature is then verified on-chain when the order is created or fulfilled. This approach allows for:

1. Gas-efficient order creation, as the order can be stored off-chain until it's ready to be fulfilled.
2. Flexibility in order submission, as anyone can submit a signed order to the contract on behalf of the seller.
3. Security, as the contract verifies that the order was indeed signed by the ticket owner, regardless of who submits the transaction.

### Key Features

1. Create signed sell orders for NFT tickets (by seller or through a relayer)
2. Cancel existing sell orders (by seller or through a relayer)
3. Fulfill (buy) existing sell orders (by buyer or through a relayer)
4. Automatic royalty payments to creators
5. Integration with ERC20 stable coin for payments
6. Support for gasless transactions using ERC20 permit

### Contract Structure

- **SignedOrder**: A struct representing a signed order for selling a ticket
- **stableCoinToken**: The ERC20 token used for all payments in the marketplace
- **registry**: The address of the registry contract
- **signedOrders**: Mapping to store signed orders by their hash
- **cancelledOrFulfilled**: Mapping to track cancelled or fulfilled orders
- **relayerOfEngine**: Mapping to track authorized relayers
- **orderIndex**: A counter for order IDs
- **orderIndexToHash** and **orderHashToIndex**: Mappings to relate order IDs and hashes

### SignedOrder Struct

The `SignedOrder` struct is used to represent a signed order for selling a ticket. It contains the following fields:

- **seller**: The address of the ticket seller
- **eventImplementation**: The address of the NFT contract
- **tokenId**: The ID of the ticket (NFT) being sold
- **price**: The price of the ticket in stable coin tokens
- **expirationTime**: The timestamp when the order expires

### Signed Order Signature

The signature is generated off-chain and used to verify the authenticity of the order. The signature is verified on-chain when the order is created or fulfilled.

### Signed Order Creation and Verification

In `TicketMarketPlace.sol`, the process of creating and verifying a signed order is a crucial security measure. This process ensures that only valid orders from legitimate sellers are processed. Here's a detailed explanation of this concept:

1. **Order Creation**: A `SignedOrder` struct is created with the seller's details, ticket information, and the seller's signature.

2. **Order Hashing**: The order details are hashed to create a unique identifier for the order.

3. **Signature Verification**: The contract verifies that the provided signature matches the hash of the order and was indeed signed by the seller.

Here's an example of how this process works in the contract:

```solidity
function createSignedOrderBySeller(
    address _seller,
    address _eventImplementation,
    uint256 _tokenId,
    uint256 _price,
    uint256 _expirationTime,
    bytes memory _signature
) public returns (bytes32 orderHash) {
    // Create the order struct
    SignedOrder memory order = SignedOrder({
        seller: _seller,
        eventImplementation: _eventImplementation,
        tokenId: _tokenId,
        price: _price,
        expirationTime: _expirationTime
    });

    // Hash the order
    orderHash = _hashOrder(order);

    // Verify the signature
    require(_verifySignature(orderHash, _signature, _seller), "Invalid signature");
```

### Main Functions

#### `createSignedOrderByEngine`

Creates a new signed order for selling a ticket, called by an authorized relayer.

```solidity
function createSignedOrderByEngine(
    address _eventImplementation,
    uint256 _tokenId,
    uint256 _price,
    uint256 _expirationTime,
    address _seller,
    bytes memory _signature
) external onlyRelayerOfEngine returns (uint256)
```

#### `createSignedOrderBySeller`

Creates a new signed order for selling a ticket, called by the seller directly.

```solidity
function createSignedOrderBySeller(
    address _eventImplementation,
    uint256 _tokenId,
    uint256 _price,
    uint256 _expirationTime,
    bytes memory _signature
) external returns (uint256)
```

#### `createSignedOrderFromBytes`

Creates a new signed order from a bytes object containing all necessary data.

```solidity
function createSignedOrderFromBytes(bytes memory _orderData) external returns (uint256)
```

#### `cancelOrderByEngine`

Cancels an existing order, called by an authorized relayer.

```solidity
function cancelOrderByEngine(bytes32 _orderHash, address _seller) external onlyRelayerOfEngine
```

#### `cancelOrderBySeller`

Cancels an existing order, called by the seller directly.

```solidity
function cancelOrderBySeller(bytes32 _orderHash) external
```

#### `fulfillOrderByEngine`

Fulfills an existing order by purchasing the ticket, called by an authorized relayer.

```solidity
function fulfillOrderByEngine(bytes32 _orderHash, address _buyer) external onlyRelayerOfEngine
```

#### `fulfillOrderByBuyer`

Fulfills an existing order by purchasing the ticket, called by the buyer directly.

```solidity
function fulfillOrderByBuyer(bytes32 _orderHash) external
```

#### `fulfillOrderByBuyerWithPermit`

Fulfills an order using ERC20 permit for gasless approval.

```solidity
function fulfillOrderByBuyerWithPermit(
    bytes32 _orderHash,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
) external
```

#### `fulfillOrderByEngineWithPermit`

Fulfills an order using ERC20 permit, called by an authorized relayer.

```solidity
function fulfillOrderByEngineWithPermit(
    bytes32 _orderHash,
    address _buyer,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
) external onlyRelayerOfEngine
```

### Events

- `OrderCreated`: Emitted when a new order is created
- `OrderCancelled`: Emitted when an order is cancelled
- `OrderFulfilled`: Emitted when an order is fulfilled (ticket is sold)
- `RoyaltyPaid`: Emitted when a royalty payment is made
- `RelayerOfEngineSet`: Emitted when a relayer's status is updated

### IERC20Permit Functionality in TicketMarketPlace

The TicketMarketPlace contract integrates IERC20Permit functionality to enable gasless transactions and streamline the order fulfillment process. This feature is particularly useful as it eliminates the need for separate token approval transactions.

#### Key Benefits:

1. **Gasless Approvals**: Users can approve token spending without submitting a separate transaction, saving on gas fees.
2. **Single-Transaction Fulfillment**: Orders can be fulfilled in a single transaction, combining approval and transfer.
3. **Enhanced User Experience**: Simplifies the process for users, especially those new to blockchain interactions.

#### Implementation:

The contract includes two functions that utilize IERC20Permit:

1. `fulfillOrderByBuyerWithPermit`: Allows a buyer to fulfill an order using a permit.
2. `fulfillOrderByEngineWithPermit`: Enables a relayer to fulfill an order on behalf of a buyer using a permit.

Both functions use the `permit` method of the IERC20Permit interface:

```solidity
IERC20Permit(address(stableCoinToken)).permit(
    buyer,
    address(this),
    order.price,
    deadline,
    v,
    r,
    s
)
```

## EventEmitter.sol

The `EventEmitter.sol` contract is responsible for managing events and their associated NFT tickets. It provides functions to get token IDs, check ownership, and handle royalty payments.
