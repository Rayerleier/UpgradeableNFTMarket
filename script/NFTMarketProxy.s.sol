// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketProxyAdmin} from "../src/NFTMarketProxyAdmin.sol";
contract NFTMarketProxyScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
        NFTMarketProxyAdmin nftMarketProxy = new NFTMarketProxyAdmin();
    }
}