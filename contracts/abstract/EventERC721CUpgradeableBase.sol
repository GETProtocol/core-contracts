// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Context } from "./Context.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IEventImplementation } from "../interfaces/IEventImplementation.sol";
import { ICreatorToken } from "../interfaces/ICreatorToken.sol";
import { ICreatorTokenLegacy } from "../interfaces/ICreatorTokenLegacy.sol";
import { IEventERC721CStorageProxy } from "../interfaces/IEventERC721CStorageProxy.sol";

abstract contract EventERC721CUpgradeableBase is Initializable, Context, ERC2981, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    IEventERC721CStorageProxy public storageProxy;

    uint256 constant TOKEN_TYPE_ERC721 = 721;

    event AutomaticApprovalOfTransferValidatorSet(bool autoApproved);

    function __EventERC721CUpgradeableBase_init(
        string memory name_,
        string memory symbol_,
        address _storageProxy
    ) internal initializer {
        storageProxy = IEventERC721CStorageProxy(_storageProxy);
        // _emitDefaultTransferValidator();
        // _registerTokenType(getTransferValidator());
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        storageProxy.initContract(name_, symbol_);
    }

    // These functions should be uncommented as they're used in the storage proxy pattern
    // function setDefaultRoyalty(address _receiver, uint96 _royaltyFraction) external {
    //     _requireCallerIsContractOwner();
    //     storageProxy.setDefaultRoyalty(_receiver, _royaltyFraction);
    // }

    // function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _royaltyFraction) external {
    //     _requireCallerIsContractOwner();
    //     storageProxy.setTokenRoyalty(_tokenId, _receiver, _royaltyFraction);
    // }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return storageProxy.getAddressDataStorageProxy(owner).balance;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = storageProxy.getTokenDataStorageProxy(tokenId).owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return storageProxy.getNameStorageProxy();
    }

    function symbol() public view virtual override returns (string memory) {
        return storageProxy.getSymbolStorageProxy();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = EventERC721CUpgradeableBase.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return storageProxy.getTokenApprovalStorageProxy(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        storageProxy.setOperatorApprovalStorageProxy(_msgSender(), operator, approved);
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        if (storageProxy.getOperatorApprovalStorageProxy(owner, operator)) {
            return true;
        }

        if (operator == address(storageProxy.getActionProcessorStorageProxy())) {
            return true;
        }

        if (storageProxy.getAutoApproveTransfersFromValidatorStorageProxy()) {
            if (operator == address(storageProxy.getTransferValidatorStorageProxy())) {
                return true;
            }

            // return
            //     operator == address(storageProxy.getTransferValidator()) ||
            //     operator == address(storageProxy.getActionProcessor());
        }

        return false;
    }

    function transfer(address from, address to, uint256 tokenId) public virtual {
        _transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return storageProxy.getTokenDataStorageProxy(tokenId).owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = EventERC721CUpgradeableBase.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(IEventImplementation.TicketAction memory ticketAction) internal virtual {
        _safeMint(ticketAction, "");
    }

    function _safeMint(IEventImplementation.TicketAction memory ticketAction, bytes memory _data) internal virtual {
        _mint(ticketAction);
        require(
            _checkOnERC721Received(address(0), ticketAction.to, ticketAction.tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(IEventImplementation.TicketAction memory ticketAction) internal virtual {
        require(ticketAction.to != address(0), "ERC721: mint to the zero address");
        require(!_exists(ticketAction.tokenId), "ERC721: token already minted");

        // _beforeTokenTransfer(address(0), ticketAction.to, ticketAction.tokenId);

        storageProxy.setTokenDataStorageProxy(
            ticketAction.tokenId,
            IEventImplementation.TokenData(ticketAction.to, ticketAction.basePrice, 0)
        );

        // this can be made more efficient by using the storageProxy.mintStorageProxy() function, could be only 1 e
        IEventImplementation.AddressData memory addressData = storageProxy.getAddressDataStorageProxy(ticketAction.to);

        addressData.balance += 1;

        storageProxy.setAddressDataStorageProxy(ticketAction.to, addressData);

        emit Transfer(address(0), ticketAction.to, ticketAction.tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = EventERC721CUpgradeableBase.ownerOf(tokenId);

        // _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // replacement for all the lines below
        storageProxy.burnTokenDataStorageProxy(tokenId);

        // _afterTokenTransfer(owner, address(0), tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner

        _approve(address(0), tokenId);

        // update storage data
        storageProxy.manageTokenTransferStorageProxy(tokenId, from, to);

        // _afterTokenTransfer(from, to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        storageProxy.setTokenApprovalStorageProxy(tokenId, to);
        emit Approval(EventERC721CUpgradeableBase.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        _validateBeforeTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId) internal virtual {
        _validateAfterTransfer(from, to, firstTokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC2981) returns (bool) {
        return
            interfaceId == type(ICreatorToken).interfaceId ||
            interfaceId == type(ICreatorTokenLegacy).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getTransferValidationFunction() external pure returns (bytes4 functionSignature, bool isViewFunction) {
        functionSignature = bytes4(keccak256("validateTransfer(address,address,address,uint256)"));
        isViewFunction = true;
    }

    // This function should be uncommented for proper token type handling
    function _tokenType() internal pure returns (uint16) {
        return uint16(TOKEN_TYPE_ERC721);
    }

    // These initialization functions should be uncommented
    // function _emitDefaultTransferValidator() internal {
    //     // emit DefaultTransferValidatorSet(address(0));
    // }

    function _registerTokenType(address validator) internal {
        // TODO add additional validation if needed - look into this
        // storageProxy.setTransferValidatorStorageProxy(validator);
    }

    function _validateBeforeTransfer(address from, address to, uint256 tokenId) internal virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
    }

    function _validateAfterTransfer(address from, address to, uint256 tokenId) internal virtual {
        // TODO add additional validation if needed - look into this
        // Additional validation if needed
    }

    uint256[44] internal __gap;
}
