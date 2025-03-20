// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPaymentSplitterFactory {
    function deployPaymentSplitter(
        address _eventAddress,
        address _relayerAddress,
        address[] memory _payeesRoyalty,
        uint256[] memory _sharesRoyalty
    ) external returns (address paymentSplitter_);
}
