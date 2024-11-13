//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract HelperConfig is Script{

  uint8 public constant DECIMALS = 8;
  int256 public constant INITIAL_PRICE= 2000e8;

  struct NetworkConfig{
    address priceFeed;
  }

  NetworkConfig public activeNetworkConfig;

  constructor() {
    if (block.chainid == 11155111) { // Sepolia
        activeNetworkConfig = getSepoliaETHConfig();
    } else if (block.chainid == 1) { // Mainnet
        activeNetworkConfig = getMainnetETHConfig();
    } else {
      activeNetworkConfig = getAnvilETHConfig();
    }
  }

  function getSepoliaETHConfig() public pure returns (NetworkConfig memory){
    NetworkConfig memory sepoliaConfig = NetworkConfig({
      priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
    });
    return sepoliaConfig;
  }

  function getAnvilETHConfig() public returns (NetworkConfig memory){
    if (activeNetworkConfig.priceFeed != address(0)) {
      return activeNetworkConfig;
    }

    vm.startBroadcast();
    MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
    vm.stopBroadcast();

    NetworkConfig memory anvilConfig = NetworkConfig({
      priceFeed: address(mockPriceFeed)
    });

    return anvilConfig;
  }

  function getMainnetETHConfig() public pure returns (NetworkConfig memory){
    NetworkConfig memory mainnetConfig = NetworkConfig({
        priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    });
    return mainnetConfig;
  }
    
  
}