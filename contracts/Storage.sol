// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import './Player.sol';

contract Storage is Ownable {
    
    using SafeMath for uint256;
    
    address[] private contractsVersion;
    
    mapping (bytes32 => string) internal stringStorage;
    
    mapping (bytes32 => address) internal addressStorage;
    
    mapping (bytes32 => uint) internal uintStorage;
    
    mapping (bytes32 => bool) internal boolStorage;
    
    mapping (bytes32 => mapping(address => bool)) internal boolStorage;
    
    function upgradeVersion(address _newVersion, address _oldVersion) external onlyOwner {
        for (uint i = 0; i != contractsVersion.length; i.add(1)) {
            if (contractsVersion[i] == _oldVersion) {
                contractsVersion[i] = _newVersion;
            }
        }
    }
    
    function addContract(address _contract) external onlyOwner {
        contractsVersion.push(_contract);
    }
    
    function removeContract(address _contract) external onlyOwner {
        for (uint i = 0; i != contractsVersion.length; i.add(1)) {
            if (contractsVersion[i] == _contract) {
                delete contractsVersion[i];
            }
        }
    }
    
    modifier onlyLatestVersion() {
        uint i = 0;
        for (; i != contractsVersion.length; i.add(1)) {
            if (contractsVersion[i] == _msgSender()) {
                break;
            }
        }
        require(_msgSender() == contractsVersion[i] || _msgSender() == owner());
        _;
    }
    
    // *** Getter Methods ***
    function getUint(bytes32 _key) external view onlyLatestVersion returns(uint) {
        return uintStorage[_key];
    }

    function getAddress(bytes32 _key) external view onlyLatestVersion returns(address) {
        return addressStorage[_key];
    }
    
    function getString(bytes32 _key) external view onlyLatestVersion returns(string memory) {
        return stringStorage[_key];
    }

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) onlyLatestVersion external {
        uintStorage[_key] = _value;
    }

    function setAddress(bytes32 _key, address _value) onlyLatestVersion external {
        addressStorage[_key] = _value;
    }
    
    function setString(bytes32 _key, string memory _value) onlyLatestVersion external {
        stringStorage[_key] = _value;
    }

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) onlyLatestVersion external {
        delete uintStorage[_key];
    }

    function deleteAddress(bytes32 _key) onlyLatestVersion external {
        delete addressStorage[_key];
    }
    
    function deleteString(bytes32 _key) onlyLatestVersion external {
        delete stringStorage[_key];
    }
    
}