// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ^0.8.4;

import { ICreatorToken } from "../interfaces/ICreatorToken.sol";
import { ICreatorTokenLegacy } from "../interfaces/ICreatorTokenLegacy.sol";
import { ITransferValidator } from "../interfaces/ITransferValidator.sol";
import { Context } from "./Context.sol";

// lib/creator-token-standards/src/interfaces/ITransferValidatorSetTokenType.sol

interface ITransferValidatorSetTokenType {
    function setTokenTypeOfCollection(address collection, uint16 tokenType) external;
}

// lib/creator-token-standards/src/access/OwnablePermissions.sol

abstract contract OwnablePermissions is Context {
    function _requireCallerIsContractOwner() internal view virtual;
}

// lib/creator-token-standards/src/utils/TransferValidation.sol

/**
 * @title TransferValidation
 * @author Limit Break, Inc.
 * @notice A mix-in that can be combined with ERC-721 contracts to provide more granular hooks.
 * Openzeppelin's ERC721 contract only provides hooks for before and after transfer.  This allows
 * developers to validate or customize transfers within the context of a mint, a burn, or a transfer.
 */
abstract contract TransferValidation is Context {
    /// @dev Thrown when the from and to address are both the zero address.
    error ShouldNotMintToBurnAddress();

    /*************************************************************************/
    /*                      Transfers Without Amounts                        */
    /*************************************************************************/

    /// @dev Inheriting contracts should call this function in the _beforeTokenTransfer function to get more granular hooks.
    function _validateBeforeTransfer(address from, address to, uint256 tokenId) internal virtual {
        bool fromZeroAddress = from == address(0);
        bool toZeroAddress = to == address(0);

        if (fromZeroAddress && toZeroAddress) {
            revert ShouldNotMintToBurnAddress();
        } else if (fromZeroAddress) {
            _preValidateMint(_msgSender(), to, tokenId, msg.value);
        } else if (toZeroAddress) {
            _preValidateBurn(_msgSender(), from, tokenId, msg.value);
        } else {
            _preValidateTransfer(_msgSender(), from, to, tokenId, msg.value);
        }
    }

    /// @dev Inheriting contracts should call this function in the _afterTokenTransfer function to get more granular hooks.
    function _validateAfterTransfer(address from, address to, uint256 tokenId) internal virtual {
        bool fromZeroAddress = from == address(0);
        bool toZeroAddress = to == address(0);

        if (fromZeroAddress && toZeroAddress) {
            revert ShouldNotMintToBurnAddress();
        } else if (fromZeroAddress) {
            _postValidateMint(_msgSender(), to, tokenId, msg.value);
        } else if (toZeroAddress) {
            _postValidateBurn(_msgSender(), from, tokenId, msg.value);
        } else {
            _postValidateTransfer(_msgSender(), from, to, tokenId, msg.value);
        }
    }

    /// @dev Optional validation hook that fires before a mint
    function _preValidateMint(address caller, address to, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires after a mint
    function _postValidateMint(address caller, address to, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires before a burn
    function _preValidateBurn(address caller, address from, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires after a burn
    function _postValidateBurn(address caller, address from, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires before a transfer
    function _preValidateTransfer(
        address caller,
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /// @dev Optional validation hook that fires after a transfer
    function _postValidateTransfer(
        address caller,
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /*************************************************************************/
    /*                         Transfers With Amounts                        */
    /*************************************************************************/

    /// @dev Inheriting contracts should call this function in the _beforeTokenTransfer function to get more granular hooks.
    function _validateBeforeTransfer(address from, address to, uint256 tokenId, uint256 amount) internal virtual {
        bool fromZeroAddress = from == address(0);
        bool toZeroAddress = to == address(0);

        if (fromZeroAddress && toZeroAddress) {
            revert ShouldNotMintToBurnAddress();
        } else if (fromZeroAddress) {
            _preValidateMint(_msgSender(), to, tokenId, amount, msg.value);
        } else if (toZeroAddress) {
            _preValidateBurn(_msgSender(), from, tokenId, amount, msg.value);
        } else {
            _preValidateTransfer(_msgSender(), from, to, tokenId, amount, msg.value);
        }
    }

    /// @dev Inheriting contracts should call this function in the _afterTokenTransfer function to get more granular hooks.
    function _validateAfterTransfer(address from, address to, uint256 tokenId, uint256 amount) internal virtual {
        bool fromZeroAddress = from == address(0);
        bool toZeroAddress = to == address(0);

        if (fromZeroAddress && toZeroAddress) {
            revert ShouldNotMintToBurnAddress();
        } else if (fromZeroAddress) {
            _postValidateMint(_msgSender(), to, tokenId, amount, msg.value);
        } else if (toZeroAddress) {
            _postValidateBurn(_msgSender(), from, tokenId, amount, msg.value);
        } else {
            _postValidateTransfer(_msgSender(), from, to, tokenId, amount, msg.value);
        }
    }

    /// @dev Optional validation hook that fires before a mint
    function _preValidateMint(
        address caller,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 value
    ) internal virtual {}

    /// @dev Optional validation hook that fires after a mint
    function _postValidateMint(
        address caller,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 value
    ) internal virtual {}

    /// @dev Optional validation hook that fires before a burn
    function _preValidateBurn(
        address caller,
        address from,
        uint256 tokenId,
        uint256 amount,
        uint256 value
    ) internal virtual {}

    /// @dev Optional validation hook that fires after a burn
    function _postValidateBurn(
        address caller,
        address from,
        uint256 tokenId,
        uint256 amount,
        uint256 value
    ) internal virtual {}

    /// @dev Optional validation hook that fires before a transfer
    function _preValidateTransfer(
        address caller,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 value
    ) internal virtual {}

    /// @dev Optional validation hook that fires after a transfer
    function _postValidateTransfer(
        address caller,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 value
    ) internal virtual {}
}

// lib/creator-token-standards/src/utils/CreatorTokenBase.sol

/**
 * @title CreatorTokenBase
 * @author Limit Break, Inc.
 * @notice CreatorTokenBaseV3 is an abstract contract that provides basic functionality for managing token
 * transfer policies through an implementation of ICreatorTokenTransferValidator/ICreatorTokenTransferValidatorV2/ICreatorTokenTransferValidatorV3.
 * This contract is intended to be used as a base for creator-specific token contracts, enabling customizable transfer
 * restrictions and security policies.
 *
 * <h4>Features:</h4>
 * <ul>Ownable: This contract can have an owner who can set and update the transfer validator.</ul>
 * <ul>TransferValidation: Implements the basic token transfer validation interface.</ul>
 *
 * <h4>Benefits:</h4>
 * <ul>Provides a flexible and modular way to implement custom token transfer restrictions and security policies.</ul>
 * <ul>Allows creators to enforce policies such as account and codehash blacklists, whitelists, and graylists.</ul>
 * <ul>Can be easily integrated into other token contracts as a base contract.</ul>
 *
 * <h4>Intended Usage:</h4>
 * <ul>Use as a base contract for creator token implementations that require advanced transfer restrictions and
 *   security policies.</ul>
 * <ul>Set and update the ICreatorTokenTransferValidator implementation contract to enforce desired policies for the
 *   creator token.</ul>
 *
 * <h4>Compatibility:</h4>
 * <ul>Backward and Forward Compatible - V1/V2/V3 Creator Token Base will work with V1/V2/V3 Transfer Validators.</ul>
 */
abstract contract CreatorTokenBase is OwnablePermissions, TransferValidation, ICreatorToken {
    /// @dev Thrown when setting a transfer validator address that has no deployed code.
    error CreatorTokenBase__InvalidTransferValidatorContract();

    /// @dev The default transfer validator that will be used if no transfer validator has been set by the creator.
    address public constant DEFAULT_TRANSFER_VALIDATOR = address(0x721C0078c2328597Ca70F5451ffF5A7B38D4E947);

    /// @dev Used to determine if the default transfer validator is applied.
    /// @dev Set to true when the creator sets a transfer validator address.
    bool private isValidatorInitialized;
    /// @dev Address of the transfer validator to apply to transactions.
    address private transferValidator;

    constructor() {
        _emitDefaultTransferValidator();
        _registerTokenType(DEFAULT_TRANSFER_VALIDATOR);
    }

    /**
     * @notice Sets the transfer validator for the token contract.
     *
     * @dev    Throws when provided validator contract is not the zero address and does not have code.
     * @dev    Throws when the caller is not the contract owner.
     *
     * @dev    <h4>Postconditions:</h4>
     *         1. The transferValidator address is updated.
     *         2. The `TransferValidatorUpdated` event is emitted.
     *
     * @param transferValidator_ The address of the transfer validator contract.
     */
    function setTransferValidator(address transferValidator_) public {
        _requireCallerIsContractOwner();

        bool isValidTransferValidator = transferValidator_.code.length > 0;

        if (transferValidator_ != address(0) && !isValidTransferValidator) {
            revert CreatorTokenBase__InvalidTransferValidatorContract();
        }

        emit TransferValidatorUpdated(address(getTransferValidator()), transferValidator_);

        isValidatorInitialized = true;
        transferValidator = transferValidator_;

        _registerTokenType(transferValidator_);
    }

    /**
     * @notice Returns the transfer validator contract address for this token contract.
     */
    function getTransferValidator() public view override returns (address validator) {
        validator = transferValidator;

        if (validator == address(0)) {
            if (!isValidatorInitialized) {
                validator = DEFAULT_TRANSFER_VALIDATOR;
            }
        }
    }

    /**
     * @dev Pre-validates a token transfer, reverting if the transfer is not allowed by this token's security policy.
     *      Inheriting contracts are responsible for overriding the _beforeTokenTransfer function, or its equivalent
     *      and calling _validateBeforeTransfer so that checks can be properly applied during token transfers.
     *
     * @dev Be aware that if the msg.sender is the transfer validator, the transfer is automatically permitted, as the
     *      transfer validator is expected to pre-validate the transfer.
     *
     * @dev Throws when the transfer doesn't comply with the collection's transfer policy, if the transferValidator is
     *      set to a non-zero address.
     *
     * @param caller  The address of the caller.
     * @param from    The address of the sender.
     * @param to      The address of the receiver.
     * @param tokenId The token id being transferred.
     */
    function _preValidateTransfer(
        address caller,
        address from,
        address to,
        uint256 tokenId,
        uint256 /*value*/
    ) internal virtual override {
        address validator = getTransferValidator();

        if (validator != address(0)) {
            if (msg.sender == validator) {
                return;
            }

            ITransferValidator(validator).validateTransfer(caller, from, to, tokenId);
        }
    }

    /**
     * @dev Pre-validates a token transfer, reverting if the transfer is not allowed by this token's security policy.
     *      Inheriting contracts are responsible for overriding the _beforeTokenTransfer function, or its equivalent
     *      and calling _validateBeforeTransfer so that checks can be properly applied during token transfers.
     *
     * @dev Be aware that if the msg.sender is the transfer validator, the transfer is automatically permitted, as the
     *      transfer validator is expected to pre-validate the transfer.
     *
     * @dev Used for ERC20 and ERC1155 token transfers which have an amount value to validate in the transfer validator.
     * @dev The `tokenId` for ERC20 tokens should be set to `0`.
     *
     * @dev Throws when the transfer doesn't comply with the collection's transfer policy, if the transferValidator is
     *      set to a non-zero address.
     *
     * @param caller  The address of the caller.
     * @param from    The address of the sender.
     * @param to      The address of the receiver.
     * @param tokenId The token id being transferred.
     * @param amount  The amount of token being transferred.
     */
    function _preValidateTransfer(
        address caller,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 /*value*/
    ) internal virtual override {
        address validator = getTransferValidator();

        if (validator != address(0)) {
            if (msg.sender == validator) {
                return;
            }

            ITransferValidator(validator).validateTransfer(caller, from, to, tokenId, amount);
        }
    }

    function _tokenType() internal pure virtual returns (uint16);

    function _registerTokenType(address validator) internal {
        if (validator != address(0)) {
            uint256 validatorCodeSize;
            assembly {
                validatorCodeSize := extcodesize(validator)
            }
            if (validatorCodeSize > 0) {
                try
                    ITransferValidatorSetTokenType(validator).setTokenTypeOfCollection(address(this), _tokenType())
                {} catch {}
            }
        }
    }

    /**
     * @dev  Used during contract deployment for constructable and cloneable creator tokens
     * @dev  to emit the `TransferValidatorUpdated` event signaling the validator for the contract
     * @dev  is the default transfer validator.
     */
    function _emitDefaultTransferValidator() internal {
        emit TransferValidatorUpdated(address(0), DEFAULT_TRANSFER_VALIDATOR);
    }
}
