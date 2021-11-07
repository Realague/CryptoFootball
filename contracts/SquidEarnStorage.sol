// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol';
import './Storage.sol';

contract SquidEarnStorage is Storage {
    
    using SafeMath for uint256;
    
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;
    
    string playerKey = "player";
    
    address latestVersion;
    
    Player[] private players;
    
    uint[] public rarities;
    
    function _getPlayerKey(uint _tokenId) internal view returns (bytes32) {
       return keccak256(abi.encodePacked(playerKey, _tokenId));
    }
    
    function setRarity(uint[] memory _rarities) external {
        uint percentage = 0;
        for (uint i = 0; i != _rarities.length; i.add(1)) {
            percentage.add(_rarities[i]); 
        }
        require(percentage == 100);
        rarities = _rarities;
    }

    function addPlayer(Player memory _player) external {
        players.push(_player);
    }
    
    function getPlayer(uint _tokenId) external view returns (Player memory) {
        return players[_tokenId];
    }
    
   function getPlayersByAdress(address _owner) external view returns (Player[] memory) {
        Player[] memory result;
        uint counter = 0;
        for (uint i = 0; i != players.length; i.add(1)) {
            if (addressStorage[_getPlayerKey(i)] == _owner) {
                result[counter] = players[i];
                counter.add(1);
            }
        }
        return result;
    }
    
}