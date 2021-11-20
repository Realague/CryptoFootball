// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./Storage.sol";
import "./MarketItem.sol";

contract CryptoFootballStorage is Storage {
    
    using SafeMath for uint256;
        
    Player[] private players;
    
    MarketItem[] private marketItems;
    
    IERC20 internal cryptoFootballToken;
    
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    constructor(address _cryptoFootballToken) {
        cryptoFootballToken  = IERC20(_cryptoFootballToken);
    }
    
    function setCryptoFootballToken(address _cryptoFootballToken) external onlyWhitelistedContract {
        cryptoFootballToken = IERC20(_cryptoFootballToken);
    }
    
    function getCryptoFootballToken() external view onlyWhitelistedContract returns (IERC20) {
        return cryptoFootballToken;
    }
    
    function getNumberMarketItems() external view onlyWhitelistedContract returns (uint) {
        return marketItems.length;
    }
    
    function getMarketItems() external view onlyWhitelistedContract returns (MarketItem[] memory) {
        return marketItems;
    }
    
    function getMarketItem(uint id) external view onlyWhitelistedContract returns (MarketItem memory) {
        return marketItems[id];
    }
    
    function addMarketItems(MarketItem memory marketItem) external onlyWhitelistedContract {
        marketItems.push(marketItem);
    }
    
    function setMarketItem(MarketItem memory marketItem) external onlyWhitelistedContract {
        require(marketItem.itemId < marketItems.length);
        marketItems[marketItem.itemId] = marketItem;
    }
    
    function getNumberPlayers() external view returns (uint) {
        return players.length;
    }

    function createPlayer(Player memory player) external onlyWhitelistedContract returns (Player memory) {
        player.id = players.length;
        players.push(player);
        return player;
    }


    function setPlayer(Player memory player) external onlyWhitelistedContract {
        require(player.id < players.length);
        players[player.id] = player;
    }
    
    function getPlayer(uint tokenId) external view returns (Player memory) {
        return players[tokenId];
    }
    
   function getPlayersByAdress(address owner) external view returns (Player[] memory) {
        Player[] memory result;
        uint counter = 0;
        for (uint i = 0; i < players.length; i++) {
            if (addressStorage[keccak256(abi.encodePacked("player", i))] == owner) {
                result[counter] = players[i];
                counter.add(1);
            }
        }
        return result;
    }
    
    function getOperatorApproval(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function setOperatorApproval(address owner, address operator, bool approval) external {
        _operatorApprovals[owner][operator] = approval;
    }
    
}