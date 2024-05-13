pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

contract NFTMarketProxyAdmin is TransparentUpgradeableProxy,Initializable {
    constructor(
        
    ){_disableInitializers();}

   
    function initialize(address _logic, address initialOwner, bytes memory _data) public initializer {
        TransparentUpgradeableProxy( _logic,  initialOwner,   _data);
    }

    

    function  getAdminAddress() external returns(address) {
        return _proxyAdmin();
    }

    receive() external payable{
        _fallback();
    }

}
