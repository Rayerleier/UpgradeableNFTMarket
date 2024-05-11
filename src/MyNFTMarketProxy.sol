pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol";

contract NFTMarketProxy {
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        keccak256("eip1967.proxy.implementation");
    bytes32 internal constant _ADMIN_SLOT = keccak256("eip1967.proxy.admin");

    constructor() {
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = msg.sender;
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function upgradeTo(address _newImplementation) external{
        _setImplementation(_newImplementation);        
    }

    function _setImplementation(address _newImplementation)internal {
        require(_newImplementation.code.length>0,"Uncorrect Implementation");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _newImplementation;
    }
    
    function _getAdmin() internal view returns(address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    function updateAdmin(address _newAdmin)external {
        require(_getAdmin()==msg.sender, "OnlyAdmin");
        require(_newAdmin.code.length>0, "Wrong new admin");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = _newAdmin;
    }

    function _getImplementation() internal view returns(address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    receive() external payable{
        _fallback();
    }

    fallback() external payable{
        _fallback();
    }

    function _fallback() internal {
        if(msg.sender != _getAdmin()){
            _delegate(_getImplementation());
        }else{
            address _implemetationADdress = abi.decode(msg.data[4:],(address));
            _setImplementation(_implemetationADdress);
        }
    }


}
