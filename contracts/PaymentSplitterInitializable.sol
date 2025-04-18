// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Context } from "./abstract/Context.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { IPaymentSplitterInitializable } from "./interfaces/IPaymentSplitterInitializable.sol";
import { IEventEmitter } from "./interfaces/IEventEmitter.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitterInitializable is Context, IPaymentSplitterInitializable {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(address indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event SharesSet(address indexed account, uint256 shares);
    event ReleasedSet(address indexed account, uint256 released);
    event PayeesSet(address[] payees);
    event PausedSet(bool isPaused);

    bool private _paymentSplitterInitialized;
    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    bool public isPaused;

    IEventEmitter public eventEmitter;
    address public eventAddress;

    IRegistry public registry;

    /**
     * @dev Throws if called by any account other than an Open Ticketing Ecosystem Relayer admin account.
     */
    modifier onlyIntegratorAdmin() {
        registry.auth().hasIntegratorAdminRole(msg.sender);
        _;
    }
    /**
     * @dev Initializes an instance of `PaymentSplitter` where each account in `payees`
     * is assigned the number of shares at the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function initializePaymentSplitter(
        address _eventAddress,
        address[] calldata payees,
        uint256[] calldata shares_,
        address _registry
    ) external {
        registry = IRegistry(_registry);

        eventAddress = _eventAddress;
        require(!_paymentSplitterInitialized, "PaymentSplitter: already initialized");
        eventEmitter = IEventEmitter(IRegistry(_registry).eventEmitterAddress());
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }

        _paymentSplitterInitialized = true;

        isPaused = false;
    }

    function releaseTokensOfToken(IERC20 token) external returns (uint256[] memory, address[] memory) {
        uint256[] memory amounts = new uint256[](_payees.length);
        address[] memory payees = new address[](_payees.length);

        if (isPaused) {
            return (amounts, payees);
        }

        for (uint256 i = 0; i < _payees.length; i++) {
            amounts[i] = release(token, _payees[i]);
            payees[i] = _payees[i];
        }

        emit ERC20FundsReleased(amounts, payees);

        eventEmitter.emitERC20FundsReleased(eventAddress, address(token), amounts, payees);

        return (amounts, payees);
    }

    function releaseNativeFunds() external returns (uint256[] memory, address[] memory) {
        uint256[] memory amounts = new uint256[](_payees.length);
        address[] memory payees = new address[](_payees.length);

        if (isPaused) {
            return (amounts, payees);
        }

        for (uint256 i = 0; i < _payees.length; i++) {
            amounts[i] = release(payable(_payees[i]));
            payees[i] = _payees[i];
        }

        emit NativeFundsReleased(amounts, payees);

        eventEmitter.emitNativeFundsReleased(eventAddress, amounts, payees);

        return (amounts, payees);
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
        eventEmitter.emitPaymentReceivedNative(eventAddress, address(this), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20 token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(account, totalReceived, released(token, account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual returns (uint256) {
        _checkPaused();
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
        _totalReleased += payment;
        unchecked {
            _released[account] += payment;
        }

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);

        return payment;
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual returns (uint256) {
        _checkPaused();
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _erc20TotalReleased[token] is the sum of all values in _erc20Released[token].
        // If "_erc20TotalReleased[token] += payment" does not overflow,
        //then "_erc20Released[token][account] += payment" cannot overflow.
        _erc20TotalReleased[token] += payment;

        unchecked {
            _erc20Released[token][account] += payment;
        }

        SafeERC20.safeTransfer(token, account, payment);

        emit ERC20PaymentReleased(address(token), account, payment);

        eventEmitter.emitERC20PaymentReleasedSingle(eventAddress, address(token), account, payment);

        return payment;
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;

        emit PayeeAdded(account, shares_);
    }

    // Confirmation functions

    function setPauseTo(bool _isPaused) external onlyIntegratorAdmin {
        isPaused = _isPaused;
        emit PausedSet(_isPaused);
    }

    function _checkPaused() internal view {
        require(!isPaused, "PaymentSplitter: contract is paused");
    }

    function setShares(address _account, uint256 _shareAmount) external onlyIntegratorAdmin {
        _shares[_account] = _shareAmount;
        emit SharesSet(_account, _shareAmount);
    }

    function setReleased(address _account, uint256 _releasedAmount) external onlyIntegratorAdmin {
        _released[_account] = _releasedAmount;
        emit ReleasedSet(_account, _releasedAmount);
    }

    function setPayees(address[] calldata _payeesArray) external onlyIntegratorAdmin {
        _payees = _payeesArray;
        emit PayeesSet(_payeesArray);
        eventEmitter.emitPayeesSet(eventAddress, _payeesArray);
    }
}
