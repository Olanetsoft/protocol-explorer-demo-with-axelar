// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Importing necessary contracts and interfaces from the Axelar network SDK
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";


import {IERC20} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol";

// Bounty contract which extends AxelarExecutable
contract Bounty is AxelarExecutable {

    // Immutable variable for the Axelar gas service
    IAxelarGasService public immutable gasService;

    // State variables to keep track of received amount and bounty recipients
    uint256 public amountReceived;
    address[] public bountyRecipients;

    // Constructor sets up the contract by initializing Axelar Gateway and Gas Service
    constructor(
        address gateway_,
        address gasReceiver_
    ) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
    }

    // Function to send tokens to multiple addresses across different chains
    function sendToMany(
        string memory destinationChain,
        string memory destinationAddress,
        address[] calldata destinationAddresses,
        string memory symbol,
        uint256 amount
    ) external payable {
        require(msg.value > 0, "Gas payment is required");

        // Getting the token address for the provided symbol
        address tokenAddress = gateway.tokenAddresses(symbol);

        // Transferring tokens from sender to this contract and approving gateway for the amount
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenAddress).approve(address(gateway), amount);

        // Encoding the destination addresses in a payload
        bytes memory payload = abi.encode(destinationAddresses);

        // Paying gas in native currency and initiating the cross-chain call
        gasService.payNativeGasForContractCallWithToken{value: msg.value}(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            symbol,
            amount,
            msg.sender
        );
        gateway.callContractWithToken(
            destinationChain,
            destinationAddress,
            payload,
            symbol,
            amount
        );
    }

    // View function to get the list of bounty recipients
    function getRecipients() public view returns (address[] memory) {
        return bountyRecipients;
    }

    // Internal function override to execute token transfer upon cross-chain call
    function _executeWithToken(
        string calldata,
        string calldata,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal override {
        // Decoding the payload to get recipient addresses
        address[] memory recipients = abi.decode(payload, (address[]));
        address tokenAddress = gateway.tokenAddresses(tokenSymbol);

        // Setting state variables for amount received and recipients
        amountReceived = amount;
        bountyRecipients = recipients;

        // Distributing the tokens equally among the recipients
        uint256 sentAmount = amount / recipients.length;
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(tokenAddress).transfer(recipients[i], sentAmount);
        }
    }
}