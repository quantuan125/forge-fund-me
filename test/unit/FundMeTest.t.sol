//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {FundMe} from "../../src/FundMe.sol";
import {PriceConverter} from "../../src//PriceConverter.sol"; 
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
  FundMe fundMe;

  address USER = makeAddr("user");
  uint256 constant SEND_VALUE = 0.1 ether;
  uint256 constant STARTING_BALANCE = 10 ether;
  uint256 constant GAS_PRICE = 1;

  function setUp() external {
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
    vm.deal(USER, STARTING_BALANCE);
  }

  modifier funded() {
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();
    _;
  }

  function testMinimumDollar() view public {
    console.log(fundMe.MINIMUM_USD());
    assertEq(fundMe.MINIMUM_USD(), 5e18);
  }

  function testOwnerIsMsgSender() view public {
    console.log(fundMe.i_owner());
    console.log(msg.sender);
    console.log(address(this));
    assertEq(fundMe.i_owner(), msg.sender);
  }

  function testPriceFeedVersion() view public {
    uint256 version = PriceConverter.getVersion(fundMe.getPriceFeed());
    assertEq(version, 0);
  }

  function testFundFailsWithoutEnoughETH() public {
    vm.expectRevert();

    fundMe.fund();
  }

  function testFundUpdatesFunded() public {
    vm.prank(USER);

    fundMe.fund{value: SEND_VALUE}();

    uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);

    assertEq(amountFunded, SEND_VALUE);

  }

  function testAddsFundertoFunderArray() public funded {
    address funder = fundMe.getFunder(0);
    assertEq(funder, USER);
  }

  function testOnlyOwnerCanWithdraw() public funded {
    vm.expectRevert();
    vm.prank(USER);
    fundMe.withdraw();
  }

  function testWithdrawWithASingleFunder() public funded {
    //Arrange
    uint256 startingOwnerBalance = fundMe.i_owner().balance;

    uint256 startingFundMeBalance = address(fundMe).balance;

    //Act
    uint256 gasStart = gasleft();
    vm.txGasPrice(GAS_PRICE);
    vm.prank(fundMe.i_owner());
    fundMe.withdraw();
    uint256 gasEnd = gasleft();
    uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
    console.log(gasUsed);

    //Assert
    uint256 endingOwnerBalance = fundMe.i_owner().balance;

    uint256 endingFundMeBalance = address(fundMe).balance;

    assertEq(endingFundMeBalance, 0);
    assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
  }

  function testWithdrawFromAMultipleFunders() public funded {
    //Arrange
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 1;

    for (uint160 i=startingFunderIndex; i < numberOfFunders; i++) {
      hoax(address(i), SEND_VALUE);
      fundMe.fund{value: SEND_VALUE}();
    }

    uint256 startingOwnerBalance = fundMe.i_owner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    //Act
    vm.startPrank(fundMe.i_owner());
    fundMe.withdraw();
    vm.stopPrank();

    //Assert
    uint256 endingOwnerBalance = fundMe.i_owner().balance;

    assert(address(fundMe).balance == 0);
    assert(startingFundMeBalance + startingOwnerBalance == endingOwnerBalance);
  }

  function testWithdrawFromAMultipleFundersCheaper() public funded {
    //Arrange
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 1;

    for (uint160 i=startingFunderIndex; i < numberOfFunders; i++) {
      hoax(address(i), SEND_VALUE);
      fundMe.fund{value: SEND_VALUE}();
    }

    uint256 startingOwnerBalance = fundMe.i_owner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    //Act
    vm.startPrank(fundMe.i_owner());
    fundMe.cheaperWithdraw();
    vm.stopPrank();

    //Assert
    uint256 endingOwnerBalance = fundMe.i_owner().balance;

    assert(address(fundMe).balance == 0);
    assert(startingFundMeBalance + startingOwnerBalance == endingOwnerBalance);
  }
}