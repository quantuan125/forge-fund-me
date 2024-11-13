//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;

    address USER;
    address OWNER;
    address FUNDME;

    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_BALANCE = 10 ether;

    event BalanceCheck(string message, uint256 userBalance, uint256 ownerBalance, uint256 fundMeBalance);

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        FUNDME = address(fundMe);
        OWNER = fundMe.i_owner();
        USER = makeAddr("user");

        vm.deal(USER, STARTING_BALANCE);
        vm.deal(OWNER, STARTING_BALANCE);

        assertEq(USER.balance, STARTING_BALANCE, "User not funded correctly");
        assertEq(OWNER.balance, STARTING_BALANCE, "Owner not funded correctly");
        assertEq(FUNDME.balance, 0, "FundMe should start empty");
    }

    // Helper struct to track balances
    struct BalanceSnapshot {
        uint256 userBalance;
        uint256 ownerBalance;
        uint256 fundMeBalance;
    }

    // Helper functions for cleaner code
    function getBalances() private view returns (BalanceSnapshot memory) {
        return BalanceSnapshot({
            userBalance: USER.balance,
            ownerBalance: OWNER.balance,
            fundMeBalance: FUNDME.balance
        });
    }

    function testUserCanFundAndWithdraw() public {
        // Snapshot initial balances
        BalanceSnapshot memory balances = getBalances();

        // Act 1 - First funding from USER
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        // Act 2 - Second funding through script (from OWNER)
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(FUNDME, SEND_VALUE);

        // Assert funding state
        assertFunding(balances);

        // Act 3 - Withdrawal
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(FUNDME);

        // Assert final state
        assertWithdrawal(balances);
    }

    function assertFunding(BalanceSnapshot memory initial) private {
        // Check funders array
        assertEq(fundMe.getFunder(0), USER, "First funder should be USER");
        assertEq(fundMe.getFunder(1), OWNER, "Second funder should be OWNER");
        
        // Check funded amounts
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE, "User funding amount incorrect");
        assertEq(fundMe.getAddressToAmountFunded(OWNER), SEND_VALUE, "Owner funding amount incorrect");
        
        // Check FundMe balance
        assertEq(
            FUNDME.balance,
            initial.fundMeBalance + 2*SEND_VALUE,
            "FundMe balance should increase by 2*SEND_VALUE"
        );

        // Optional: Emit balance check for debugging
        emit BalanceCheck(
            "After Funding",
            USER.balance,
            OWNER.balance,
            FUNDME.balance
        );
    }

    function assertWithdrawal(BalanceSnapshot memory initial) private {
        // Check final balances
        assertEq(FUNDME.balance, 0, "FundMe should be empty after withdrawal");
        assertEq(
            USER.balance,
            initial.userBalance - SEND_VALUE,
            "User should only lose SEND_VALUE"
        );
        assertEq(
            OWNER.balance,
            initial.ownerBalance + SEND_VALUE,
            "Owner should gain SEND_VALUE (net)"
        );

        // Check cleanup
        assertEq(fundMe.getFundersLength(), 0, "Funders array should be empty");
        assertEq(
            fundMe.getAddressToAmountFunded(USER),
            0,
            "User's funded amount should be reset"
        );
        assertEq(
            fundMe.getAddressToAmountFunded(OWNER),
            0,
            "Owner's funded amount should be reset"
        );

        // Optional: Emit final balance check
        emit BalanceCheck(
            "After Withdrawal",
            USER.balance,
            OWNER.balance,
            FUNDME.balance
        );
    }
}
