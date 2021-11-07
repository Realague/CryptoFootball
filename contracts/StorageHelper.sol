// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol';
import './SquidEarnStorage.sol';

contract StorageHelper {
        
    using SafeMath for uint256;
    
    SquidEarnStorage internal squidEarnStorage;
    
    function _setRarity(uint _rarity, uint _dropRate) internal {
        squidEarnStorage.setUint(keccak256(abi.encodePacked("rarity", _rarity)), _dropRate);
    }
    
    function _getRarity(uint _rarity) internal view returns (uint) {
        return squidEarnStorage.getUint(keccak256(abi.encodePacked("rarity", _rarity)));
    }
    
    function _setPlayer(uint _tokenId, address _owner) internal {
        squidEarnStorage.setAddress(keccak256(abi.encodePacked("player", _tokenId)), _owner);
    }
    
    function _getPlayer(uint _tokenId) internal view returns (Player memory) {
        return squidEarnStorage.getPlayer(_tokenId);
    }
    
    function _getPlayerOwner(uint _tokenId) internal view returns (address) {
        return squidEarnStorage.getAddress(keccak256(abi.encodePacked("player", _tokenId)));
    }
    
    function _setMarketplaceAddress(address _contractAddress) internal {
        squidEarnStorage.setAddress(keccak256("marketplace"), _contractAddress);
    }
    
    function _getMarketplaceAdress() internal view returns (address contractAddress) {
        return squidEarnStorage.getAddress(keccak256("marketplace"));
    }
    
    function _setNumberOfPlayerOwned(address _address, uint _count) internal {
        squidEarnStorage.setUint(keccak256(abi.encodePacked("nbplayers", _address)), _count);
    }
    
    function _getNumberOfPlayerOwned(address _address) internal view returns (uint) {
        return squidEarnStorage.getUint(keccak256(abi.encodePacked("nbplayers", _address)));
    }
    
    function _setPlayerApproval(uint _tokenId, address _address) internal {
        squidEarnStorage.setAddress(keccak256(abi.encodePacked("tokenapproval", _tokenId)), _address);
    }
    
    function _getPlayerApproval(uint _tokenId) internal view returns (address) {
        return squidEarnStorage.getAddress(keccak256(abi.encodePacked("tokenapproval", _tokenId)));
    }
        
    function _setOperatorApproval(bool _tokenId, address _address) internal {
        squidEarnStorage.setAddress(keccak256(abi.encodePacked("operatorapproval", _tokenId)), _address);
    }
    
    function _getOperatorApproval(uint _tokenId) internal view returns (address) {
        return squidEarnStorage.getAddress(keccak256(abi.encodePacked("operatorapproval", _tokenId)));
    }
    
    function _getRewards(address _address) internal view returns (uint) {
        return squidEarnStorage.getUint(keccak256(abi.encodePacked("rewards", _address)));
    }
    
    function _setRewards(address _address, uint _rewards) internal {
        squidEarnStorage.setUint(keccak256(abi.encodePacked("rewards", _address)), _rewards + squidEarnStorage.getUint(keccak256(abi.encodePacked("rewards", _address))));
    }
    
    function _getGlobalRewards() internal view returns (uint) {
        return squidEarnStorage.getUint(keccak256(abi.encodePacked("globalrewards")));
    } 
    
    function _setGlobalRewards(int _rewards) internal {
        squidEarnStorage.setUint(keccak256(abi.encodePacked("globalrewards")), squidEarnStorage.getUint(keccak256(abi.encodePacked("globalrewards"))) + _rewards);
    }
}