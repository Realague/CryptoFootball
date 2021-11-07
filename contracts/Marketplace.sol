// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './StorageHelper.sol';

contract Marketplace is StorageHelper {
    
    function listPlayer(uint _id, uint _price) external {
        
    }
    
    function cancelListing(uint _id) external {
        
    }
    
    function changePrice(uint _id, uint _price) external {
        
    }
    
    function getPlayersForSale() external view returns (Player[] memory) {
        return squidEarnStorage.getPlayersByAdress(_getMarketplaceAdress());
    }
    
    function buyPlayer(uint _id) external returns (Player memory) {
        
    }
    
}