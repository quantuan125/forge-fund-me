//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol"; 
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18;
    address public immutable i_owner;

    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Must be Owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function fund() public payable {
        //PriceConverter.getConversionRate(msg.value)
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Minimum funding amount is 5 USD or ...ETH");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner() {
        uint256 fundersLength = s_funders.length;
        for (uint256 i=0; i < fundersLength; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner{
        /*starting index, ending index, step amount*/
        for (uint256 i=0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        //transfer
        // payable(msg.sender).transfer(address(this).balance);

        // //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        //call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }   

   receive() external payable {
    fund();
   }

   fallback() external payable { 
    fund();
   }

    // Getter Functions
    function getFunder(uint256 index) external view returns(address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) external view returns(uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() external view returns(AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getFundersLength() external view returns(uint256) {
        return s_funders.length;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

}