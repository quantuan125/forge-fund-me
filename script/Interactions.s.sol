//Fund

//Withdraw

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    uint256 constant DEFAULT_FUND_AMOUNT = 0.01 ether;

    function fundFundMe(
        address mostRecentlyDeployed,
        uint256 fundAmount
    ) public {
        vm.startBroadcast();
        FundMe fundMe = FundMe(payable(mostRecentlyDeployed));
        fundMe.fund{value: fundAmount}();
        vm.stopBroadcast();
        console.log(
            "Funded FundMe contract %s with %s",
            mostRecentlyDeployed,
            fundAmount
        );
    }
    function run() external {
        // Get fund amount from command line argument, or use default
        uint256 fundAmount = vm.envOr("FUND_AMOUNT", DEFAULT_FUND_AMOUNT);

        // Debug chainId
        console.log("Current chainId:", block.chainid);

        // Get the most recent deployment using DevOpsTools
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe", 
            block.chainid
        );
        console.log("Found deployment at:", mostRecentlyDeployed);

        // address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        // console.log("Using FundMe address:", mostRecentlyDeployed);

        require(mostRecentlyDeployed != address(0), "FUNDME_ADDRESS not set");

        fundFundMe(mostRecentlyDeployed, fundAmount);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe fundMe = FundMe(payable(mostRecentlyDeployed));
        fundMe.withdraw();
        vm.stopBroadcast();
        console.log("Withdrew from FundMe contract: %s", mostRecentlyDeployed);
    }
    function run() external {
        // Debug chainId
        console.log("Current chainId:", block.chainid);

        // address mostRecentlyDeployed = vm.envAddress("FUNDME_ADDRESS");
        // console.log("Using FundMe address:", mostRecentlyDeployed);

        // Get the most recent deployment using DevOpsTools
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe", 
            block.chainid
        );
        console.log("Found deployment at:", mostRecentlyDeployed);

        require(mostRecentlyDeployed != address(0), "FUNDME_ADDRESS not set");

        withdrawFundMe(mostRecentlyDeployed);
    }
}
