// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketProxyAdmin} from "../src/NFTMarketProxyAdmin.sol";
contract NFTMarketProxyScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
        NFTMarketProxyAdmin nftMarketProxy = new NFTMarketProxyAdmin(
            0x38D85C8307D119f14E60e132D7C9274Ba79DCa09,
            0xceD0324969581Fe73b5c867d1aAC8E2e33d0946E,
            ""
        );
    }
}
