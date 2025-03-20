// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IEventImplementation } from "./IEventImplementation.sol";
import { IEconomicsFactory } from "./IEconomicsFactory.sol";

interface IEventEmitter {
    // functions for the ownership oracle - view

    function getTokenIds(address eventImplementation) external view returns (uint256[] memory);

    function getTokenIdsLength(address eventImplementation) external view returns (uint256);

    function isTokenIdIssuedByEventImplementation(
        address eventImplementation,
        uint256 tokenId
    ) external view returns (bool);

    function getOwnedTokenIdsOfUser(
        address account,
        address eventImplementation
    ) external view returns (uint256[] memory);

    function getOwnedTokenIdsOfUserLength(address account, address eventImplementation) external view returns (uint256);

    function isTokenIdOwned(address account, uint256 tokenId, address eventImplementation) external view returns (bool);

    // Events and functions for the Actions Processor contract
    event Authorized(address indexed _address);

    event Unauthorized(address indexed _address);

    event PrimarySale(
        address indexed eventImplementation,
        IEventImplementation.TicketAction[] ticketActions,
        uint256 totalFuel,
        uint256 protocolFuel,
        uint256 totalFuelUSD,
        uint256 protocolFuelUSD
    );

    event SecondarySale(
        address indexed eventImplementation,
        IEventImplementation.TicketAction[] ticketActions,
        uint256 totalFuel,
        uint256 protocolFuel,
        uint256 totalFuelUSD,
        uint256 protocolFuelUSD
    );

    event Scanned(
        address indexed eventImplementation,
        IEventImplementation.TicketAction[] ticketActions,
        uint256 fuelTokens,
        uint256 fuelTokensProtocol
    );

    event CheckedIn(
        address indexed eventImplementation,
        IEventImplementation.TicketAction[] ticketActions,
        uint256 fuelTokens,
        uint256 fuelTokensProtocol
    );

    event Invalidated(
        address indexed eventImplementation,
        IEventImplementation.TicketAction[] ticketActions,
        uint256 fuelTokens,
        uint256 fuelTokensProtocol
    );

    event Claimed(address indexed eventImplementation, IEventImplementation.TicketAction[] ticketActions);

    event Transfered(address indexed eventImplementation, IEventImplementation.TicketAction[] ticketActions);

    event UpdateFinancing(address indexed eventImplementation, IEventImplementation.EventFinancing financing);

    event ActionErrorLog(
        address indexed eventImplementation,
        IEventImplementation.TicketAction ticketActions,
        IEventImplementation.ErrorFlags errorFlag,
        uint256 tokenId,
        uint64 actionId
    );

    // functions

    function emitPrimarySale(
        address eventImplementation,
        IEventImplementation.TicketAction[] memory ticketActions,
        uint256 totalFuel,
        uint256 protocolFuel,
        uint256 totalFuelUSD,
        uint256 protocolFuelUSD
    ) external;

    function emitSecondarySale(
        address eventImplementation,
        IEventImplementation.TicketAction[] memory ticketActions,
        uint256 totalFuel,
        uint256 protocolFuel,
        uint256 totalFuelUSD,
        uint256 protocolFuelUSD
    ) external;

    function authorizeByFactory(address _address) external;

    function emitActionErrorLog(
        IEventImplementation.TicketAction memory ticketActions,
        IEventImplementation.ErrorFlags errorFlag,
        uint256 tokenId,
        address eventAddress,
        uint64 actionId
    ) external;

    function emitScanned(
        address eventImplementation,
        IEventImplementation.TicketAction[] memory ticketActions,
        uint256 fuelTokens,
        uint256 fuelTokensProtocol
    ) external;

    function emitCheckedIn(
        address _eventImplementation,
        IEventImplementation.TicketAction[] memory ticketActions,
        uint256 fuelTokens,
        uint256 fuelTokensProtocol
    ) external;

    function emitInvalidated(
        address _eventImplementation,
        IEventImplementation.TicketAction[] memory ticketActions,
        uint256 fuelTokens,
        uint256 fuelTokensProtocol
    ) external;

    function emitClaimed(
        address eventImplementation,
        IEventImplementation.TicketAction[] memory ticketActions
    ) external;

    function emitTransfered(
        address eventImplementation,
        IEventImplementation.TicketAction[] memory ticketActions
    ) external;

    function authorize(address _address) external;

    function unauthorize(address _address) external;

    function returnIsAuthorized(address _address) external view returns (bool);

    // Events and functions for the event factory contract

    event EventCreated(uint256 indexed eventIndex, address indexed eventImplementationProxy);

    event RouterInUse(address indexed eventAddress, address indexed routerAddress);

    function emitEventCreated(uint256 eventIndex, address eventImplementationProxy) external;

    function emitRouterInUse(address eventAddress, address routerAddress) external;

    // Events and functions for the event implementation contract

    event TicketTransferred(address indexed eventImplementation, uint256 tokenId, address from, address to);

    event DefaultRoyaltySet(address indexed eventImplementation, address royaltySplitter, uint96 royaltyFee);

    event TokenRoyaltySet(
        address indexed eventImplementation,
        uint256 tokenId,
        address royaltySplitter,
        uint96 royaltyFee
    );

    event TicketMinted(address indexed eventImplementation, IEventImplementation.TicketAction ticketAction);

    event TicketBurned(address indexed eventImplementation, uint256 tokenId);

    event EventDataUpdated(address indexed eventImplementation, IEventImplementation.EventData eventData);

    event EventDataSet(address indexed eventImplementation, IEventImplementation.EventData eventData);

    event DefaultRoyaltyDeleted(address indexed eventImplementation);

    event TokenRoyaltyDeleted(address indexed eventImplementation, uint256 tokenId);

    function emitTicketTransferred(uint256 tokenId, address from, address to) external;

    function emitDefaultRoyaltySet(address royaltySplitter, uint96 royaltyFee) external;

    function emitTokenRoyaltySet(uint256 tokenId, address royaltySplitter, uint96 royaltyFee) external;

    // function emitTokenRoyaltyDeleted(uint256 _tokenId) external;

    // function emitDefaultRoyaltyDeleted() external;

    function emitEventDataUpdated(IEventImplementation.EventData memory eventData) external;

    function emitEventDataSet(IEventImplementation.EventData memory eventData) external;

    function emitTicketMinted(IEventImplementation.TicketAction memory ticketAction) external;

    function emitTicketBurned(uint256 tokenId) external;

    // Events and functions for the economics implementation contract

    event OverdraftEnabledStatusSet(address indexed economicsImplementation, bool shouldEnableOverdraft);

    event ToppedUp(address indexed economicsImplementation, uint256 price, uint256 amount);

    event FuelReservedFromTicks(address indexed economicsImplementation, uint256 usdAmount, uint256 fuelAmount);

    event OverdraftInterestSet(address indexed economicsImplementation, uint256 indexed interestPerYear);

    function emitOverdraftEnabledStatusSet(bool shouldEnableOverdraft) external;

    function emitToppedUp(uint256 price, uint256 amount) external;

    function emitFuelReservedFromTicks(uint256 usdAmount, uint256 fuelAmount) external;

    function emitOverdraftInterestSet(uint256 interestPerYear) external;

    event PaymentSplitterDeployed(
        address indexed eventAddress,
        address indexed paymentSplitter,
        address[] payeesRoyalty,
        uint256[] sharesRoyalty
    );

    function emitPaymentSplitterDeployed(
        address eventAddress,
        address paymentSplitter,
        address[] memory payeesRoyalty,
        uint256[] memory sharesRoyalty
    ) external;

    // Events and functions for the payment splitter initializable contract

    event PayeeAdded(address indexed eventAddress, address account, uint256 shares);

    event PaymentReleased(address indexed eventAddress, address to, uint256 amount);

    event ERC20PaymentReleased(address indexed token, address indexed eventAddress, address to, uint256 amount);

    event PaymentReceivedNative(address indexed eventAddress, address from, uint256 amount);

    event SharesSet(address indexed eventAddress, address indexed account, uint256 shares);

    event ReleasedSet(address indexed eventAddress, address indexed account, uint256 released);

    event PayeesSet(address indexed eventAddress, address[] payees);

    event PausedSet(address indexed eventAddress, bool isPaused);

    event ERC20FundsReleased(address indexed eventAddress, address indexed token, uint256[] amounts, address[] payees);

    event NativeFundsReleased(address indexed eventAddress, uint256[] amounts, address[] payees);

    event ERC20PaymentReleasedSingle(
        address indexed eventAddress,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    function emitPayeeAdded(address eventAddress, address account, uint256 shares) external;

    function emitERC20FundsReleased(
        address eventAddress,
        address token,
        uint256[] memory amounts,
        address[] memory payees
    ) external;

    function emitNativeFundsReleased(address eventAddress, uint256[] memory amounts, address[] memory payees) external;

    function emitPaymentReceivedNative(address eventAddress, address from, uint256 amount) external;

    function emitERC20PaymentReleasedSingle(address eventAddress, address token, address to, uint256 amount) external;

    function emitPayeesSet(address eventAddress, address[] memory payeesArray) external;
}
