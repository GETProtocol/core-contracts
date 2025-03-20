// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IPaymentSplitterInitializable, IERC20 } from "./interfaces/IPaymentSplitterInitializable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC2981 is IERC165 {
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

contract PaymentSplitterFactory is IERC2981, ERC165, AuthModifiers {
    error MinterCreatorSharedRoyalties__CreatorCannotBeZeroAddress();
    error MinterCreatorSharedRoyalties__CreatorSharesCannotBeZero();
    error MinterCreatorSharedRoyalties__MinterCannotBeZeroAddress();
    error MinterCreatorSharedRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
    error MinterCreatorSharedRoyalties__MinterSharesCannotBeZero();
    error MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId();
    error MinterCreatorSharedRoyalties__PaymentSplitterReferenceCannotBeZeroAddress();
    error MinterCreatorSharedRoyalties__RoyaltyFeeWillExceedSalePrice();

    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => EnumerableSet.AddressSet) private _relayerToPaymentSplitters;
    EnumerableSet.AddressSet private _activePaymentSplitters;
    EnumerableSet.AddressSet private _inactivePaymentSplitters;

    address private _paymentSplitterImplementation;
    ProxyAdmin public proxyAdmin;

    // eventAddress => relayerAddress
    mapping(address => address) private eventToRelayerAddress;

    // eventAddress => paymentSplitterAddress
    mapping(address => address) private eventToPaymentSplitter;

    address public registryAddress;

    event PaymentSplitterDeployed(
        address indexed eventAddress,
        address indexed paymentSplitter,
        address[] payeesRoyalty,
        uint256[] sharesRoyalty
    );

    constructor(address paymentSplitterImplementation_, address _registryAddress, address _proxyAdminAddress) {
        _paymentSplitterImplementation = paymentSplitterImplementation_;
        proxyAdmin = ProxyAdmin(_proxyAdminAddress);
        __AuthModifiers_init_unchained(_registryAddress);
        registryAddress = _registryAddress;
    }

    // Operational functions

    /**
     * @notice Deploy a payment splitter for an event
     * @param _eventAddress The address of the event
     * @param _relayerAddress The address of the relayer
     * @param _payeesRoyalty The payees of the royalty
     * @param _sharesRoyalty The shares of the royalty
     * @return paymentSplitter_ The address of the payment splitter
     */
    function deployPaymentSplitter(
        address _eventAddress,
        address _relayerAddress,
        address[] calldata _payeesRoyalty,
        uint256[] calldata _sharesRoyalty
    ) external onlyEventFactory returns (address paymentSplitter_) {
        paymentSplitter_ = _createPaymentSplitter(_eventAddress, _payeesRoyalty, _sharesRoyalty);
        eventToPaymentSplitter[_eventAddress] = paymentSplitter_;
        _setMinterPaymentSplitters(_relayerAddress, paymentSplitter_);
        eventToRelayerAddress[_eventAddress] = _relayerAddress;
        _activePaymentSplitters.add(paymentSplitter_);
        emit PaymentSplitterDeployed(_eventAddress, paymentSplitter_, _payeesRoyalty, _sharesRoyalty);
    }

    function releaseNativeFunds(address _eventAddress, address _releaseTo) external {
        IPaymentSplitterInitializable paymentSplitter = _getPaymentSplitterForEvent(_eventAddress);
        paymentSplitter.release(payable(_releaseTo));
    }

    function releaseERC20Funds(address _eventAddress, address _tokenAddress, address _releaseTo) external {
        IPaymentSplitterInitializable paymentSplitter = _getPaymentSplitterForEvent(_eventAddress);
        paymentSplitter.release(IERC20(_tokenAddress), _releaseTo);
    }

    // View functions

    function returnPaymentSplitter(address _eventAddress) external view returns (address) {
        return eventToPaymentSplitter[_eventAddress];
    }

    function releasableNativeFunds(address _eventAddress, address _releaseTo) external view returns (uint256) {
        IPaymentSplitterInitializable paymentSplitter = _getPaymentSplitterForEvent(_eventAddress);
        return paymentSplitter.releasable(payable(_releaseTo));
    }

    function releasableERC20Funds(
        address _eventAddress,
        address coin,
        address _releaseTo
    ) external view returns (uint256) {
        IPaymentSplitterInitializable paymentSplitter = _getPaymentSplitterForEvent(_eventAddress);
        return paymentSplitter.releasable(IERC20(coin), _releaseTo);
    }

    // Internal write functions

    function _createPaymentSplitter(
        address _eventAddress,
        address[] calldata _payeesRoyalty,
        uint256[] calldata _sharesRoyalty
    ) private returns (address) {
        bytes memory _initData = abi.encodeWithSignature(
            "initializePaymentSplitter(address,address[],uint256[],address)",
            _eventAddress,
            _payeesRoyalty,
            _sharesRoyalty,
            registryAddress
        );

        TransparentUpgradeableProxy paymentSplitter = new TransparentUpgradeableProxy(
            _paymentSplitterImplementation,
            address(proxyAdmin),
            _initData
        );

        return address(paymentSplitter);
    }

    function _setMinterPaymentSplitters(address minter, address paymentSplitter) internal {
        _relayerToPaymentSplitters[minter].add(paymentSplitter);
    }

    // View functions

    function paymentSplittersOfRelayer(address relayer) external view returns (address[] memory) {
        return _relayerToPaymentSplitters[relayer].values();
    }

    function activePaymentSplitters() external view returns (address[] memory) {
        return _activePaymentSplitters.values();
    }

    function inactivePaymentSplitters() external view returns (address[] memory) {
        return _inactivePaymentSplitters.values();
    }

    // Internal view functions

    function _getPaymentSplitterForEvent(address _eventAddress) private view returns (IPaymentSplitterInitializable) {
        address paymentSplitterForToken = eventToPaymentSplitter[_eventAddress];
        if (paymentSplitterForToken == address(0)) {
            revert MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId();
        }

        return IPaymentSplitterInitializable(payable(paymentSplitterForToken));
    }

    // Configuration functions

    function removeInactivePaymentSplitter(address paymentSplitter) external onlyIntegratorAdmin {
        _inactivePaymentSplitters.remove(paymentSplitter);
    }

    function removeActivePaymentSplitter(address paymentSplitter) external onlyIntegratorAdmin {
        _activePaymentSplitters.remove(paymentSplitter);
        _inactivePaymentSplitters.add(paymentSplitter);
    }

    function removePaymentSplitterFromRelayer(address relayer, address paymentSplitter) external onlyIntegratorAdmin {
        _relayerToPaymentSplitters[relayer].remove(paymentSplitter);
    }

        function paymentSplitterImplementation() public view virtual returns (address) {
        return _paymentSplitterImplementation;
    }

    function _setPaymentSplitterImplementation(address paymentSplitterImplementation_) internal {
        _paymentSplitterImplementation = paymentSplitterImplementation_;
    }

    /**
     * @notice Indicates whether the contract implements the specified interface.
     * @dev Overrides supportsInterface in ERC165.
     * @param interfaceId The interface id
     * @return true if the contract implements the specified interface, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external pure override returns (address receiver, uint256 royaltyAmount) {
        // dummy implementation
        royaltyAmount = (salePrice * 250) / tokenId;
        return (receiver, royaltyAmount);
    }
}
