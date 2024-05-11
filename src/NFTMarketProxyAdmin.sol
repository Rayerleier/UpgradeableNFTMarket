pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol";

contract NFTMarketProxyAdmin is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) TransparentUpgradeableProxy(logic, admin, data) {}

    function  getAdminAddress() external returns(address) {
        return _proxyAdmin();
    }

    receive() external payable{
        _fallback();
    }

}
