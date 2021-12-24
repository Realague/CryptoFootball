// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./Storage.sol";
import "./structure/MarketItem.sol";
import "./structure/Footballteam.sol";

contract FootballHeroesStorage is Storage {
    
    using SafeMath for uint256;
        
    Player[] private players;
    
    MarketItem[] private marketItems;

    mapping(address => FootballTeam) private footballTeams;
    
    IERC20 internal footballHeroesToken;
    
    IERC20 internal feeToken;
    
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    constructor(address _footballHeroesToken, address _feeToken) {
        feeToken = IERC20(_feeToken);
        footballHeroesToken = IERC20(_footballHeroesToken);
    }
    
    // *** Getter Methods ***
    function getFootballTeam(address _address) external view returns (FootballTeam memory) {
        return footballTeams[_address];
    }

    function getFeeToken() external view returns (IERC20) {
        return feeToken;
    }
    
    function getFootballHeroesToken() external view returns (IERC20) {
        return footballHeroesToken;
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
    
    function getNumberPlayers() external view returns (uint) {
        return players.length;
    }
    
    function getPlayer(uint tokenId) external view returns (Player memory) {
        return players[tokenId];
    }
    
   function getPlayers() external view returns (uint[] memory) {
        uint counter = 0;
        uint nbPlayerOwned = uintStorage[keccak256(abi.encodePacked("nbplayers", _msgSender()))];
        uint[] memory result = new uint[](nbPlayerOwned);
        for (uint i = 0; i != players.length && counter != nbPlayerOwned; i++) {
            if (addressStorage[keccak256(abi.encodePacked("player", i))] == _msgSender()) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    
    function getOperatorApproval(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    // *** Setter Methods ***
    function setFootballTeam(FootballTeam memory footballTeam, address _address) external onlyWhitelistedContract {
        footballTeams[_address] = footballTeam;
    }

    function addMarketItems(MarketItem memory marketItem) external onlyWhitelistedContract {
        marketItems.push(marketItem);
    }
    
    function setMarketItem(MarketItem memory marketItem) external onlyWhitelistedContract {
        require(marketItem.itemId < marketItems.length);
        marketItems[marketItem.itemId] = marketItem;
    }
    
    function setPlayer(Player memory player) external onlyWhitelistedContract {
        require(player.id < players.length);
        players[player.id] = player;
    }

    function createPlayer(Player memory player) external onlyWhitelistedContract returns (Player memory) {
        player.id = players.length;
        players.push(player);
        return player;
    }
    
    function setOperatorApproval(address owner, address operator, bool approval) external onlyWhitelistedContract {
        _operatorApprovals[owner][operator] = approval;
    }
    
    function setFootballHeroesToken(address _cryptoFootballToken) external onlyWhitelistedContract {
        footballHeroesToken = IERC20(_cryptoFootballToken);
    }

    function setFeeToken(address _feeToken) external onlyWhitelistedContract {
        footballHeroesToken = IERC20(_feeToken);
    }

    function withdraw(address tokenAddress) external onlyOwner {
       IERC20 token = IERC20(tokenAddress);
       require(token.balanceOf(address(this)) > 0);
       token.transfer(_msgSender(), token.balanceOf(address(this)));
   }
    
}