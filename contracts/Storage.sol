// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "./structure/Player.sol";

contract Storage is Ownable {
    
    using SafeMath for uint256;
    
    mapping(address => bool) public whiteList;
    
    mapping (bytes32 => string) internal stringStorage;
    
    mapping (bytes32 => address) internal addressStorage;
    
    mapping (bytes32 => uint) internal uintStorage;
    
    mapping (bytes32 => bool) internal boolStorage;
    
    function upgradeVersion(address oldVersion, address newVersion) external onlyOwner {
        delete whiteList[oldVersion];
        whiteList[newVersion] = true;
    }
    
    function addContract(address _contract) external onlyOwner {
        whiteList[_contract] = true;
    }
    
    function removeContract(address _contract) external onlyOwner {
        delete whiteList[_contract];
    }
    
    modifier onlyWhitelistedContract() {
        require(whiteList[_msgSender()] || _msgSender() == owner(), "Unauthorized contract");
        _;
    }
    
    // *** Getter Methods ***
    function getUint(bytes32 key) external view onlyWhitelistedContract returns (uint) {
        return uintStorage[key];
    }

    function getAddress(bytes32 key) external view onlyWhitelistedContract returns (address) {
        return addressStorage[key];
    }
    
    function getString(bytes32 key) external view onlyWhitelistedContract returns (string memory) {
        return stringStorage[key];
    }

    // *** Setter Methods ***
    function setUint(bytes32 key, uint value) external onlyWhitelistedContract {
        uintStorage[key] = value;
    }

    function setAddress(bytes32 key, address value) external onlyWhitelistedContract {
        addressStorage[key] = value;
    }
    
    function setString(bytes32 key, string memory value) external onlyWhitelistedContract {
        stringStorage[key] = value;
    }

    // *** Delete Methods ***
    function deleteUint(bytes32 key) external onlyWhitelistedContract {
        delete uintStorage[key];
    }

    function deleteAddress(bytes32 key) external onlyWhitelistedContract {
        delete addressStorage[key];
    }
    
    function deleteString(bytes32 key) external onlyWhitelistedContract {
        delete stringStorage[key];
    }
    
}