// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";
import "./StorageHelper.sol";
import "./structure/MarketItem.sol";

contract Marketplace is StorageHelper {
    
    IERC20 private listingFeeToken = IERC20(address(0x0078867bbeef44f2326bf8ddd1941a4439382ef2a7));
    
    IERC721 private playerContract;
    
    uint private listingFees = 30;
    
    uint private sellFees = 0;
    
    event MarketItemCreated(
        uint indexed itemId,
        uint indexed tokenId,
        address indexed seller,
        address owner,
        uint256 price,
        bool sold
    );
    
    constructor(address storageAdress) StorageHelper(storageAdress) {
    }
    
    modifier onlySellerOf(uint itemId) {
        require(_msgSender() == _getMarketItem(itemId).seller, "You are not the owner");
        _;
    }
    
    function setPlayerContract(address _playerContract) external onlyOwner {
        playerContract = IERC721(_playerContract);
    }
    
    function setListingFeesToken(address _listingFeeToken) external onlyOwner {
        listingFeeToken = IERC20(_listingFeeToken);
    }
    
    function setListingFees(uint _listingFees) external onlyOwner {
        listingFees = _listingFees;
    }
    
    function setSellFees(uint _sellFees) external onlyOwner {
        sellFees = _sellFees;
    }

    function listPlayer(uint tokenId, uint price) external onlyOwnerOf(tokenId) {
        require(price > 0, "Can't sell for free");
        require(listingFeeToken.balanceOf(_msgSender()) >= listingFees);
        
        MarketItem memory marketItem = MarketItem(
            _getNumberMarketItems(),
            tokenId,
            _msgSender(),
            address(0),
            price,
            false
        );
        
        _addMarketItem(marketItem);
        
        playerContract.transferFrom(_msgSender(), address(this), tokenId);
        
        emit MarketItemCreated(
            marketItem.itemId,
            tokenId,
            _msgSender(),
            address(0),
            price,
            false
        );
    }
    
    function cancelListing(uint itemId) external onlySellerOf(itemId) {
        MarketItem memory marketItem = _getMarketItem(itemId);
        
        marketItem.seller = address(0);
        _setMarketItem(marketItem);
        playerContract.transferFrom(address(this), _msgSender(), marketItem.tokenId);
    }
    
    function changePrice(uint itemId, uint price) external onlySellerOf(itemId) botPrevention {
        MarketItem memory marketItem = _getMarketItem(itemId);
        marketItem.price = price;
        _setMarketItem(marketItem);
        playerContract.transferFrom(_msgSender(), address(this), marketItem.tokenId);
    }
    
    function getPlayersForSale() external view returns (MarketItem[] memory) {
        return _getMarketItems();
    }
    
    function contains(uint[] memory array, uint value) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }
    
    function getPlayerForSaleFiltered(uint[] memory frames, uint scoreMin, uint scoreMax, uint priceMin, uint priceMax, bool sold) external view returns (MarketItem[] memory) {
        require(scoreMax >= scoreMin && priceMax >= priceMin);
        uint counter = 0;
        MarketItem[] memory marketItemsFiltered;
        MarketItem[] memory marketItem = _getMarketItems();
        for (uint i = 0; i < marketItem.length; i++) {
            Player memory player = _getPlayer(marketItem[i].tokenId);
            if (contains(frames, uint(player.frame)) &&
                player.score >= scoreMin && player.score <= scoreMax
                && marketItem[i].price >= priceMin && marketItem[i].price <= priceMax
                && marketItem[i].sold == sold && marketItem[i].seller != address(0)) {
                marketItemsFiltered[counter] = marketItem[i];
                counter++;
            }
        }
        return marketItemsFiltered;
    }
    
    function getListedPlayerOfAddress(bool sold) external view returns (MarketItem[] memory) {
        uint counter = 0;
        MarketItem[] memory marketItemsOfAddress;
        MarketItem[] memory marketItem = _getMarketItems();
        for (uint i = 0; i < marketItem.length; i++) {
            if (marketItem[i].owner == _msgSender() && sold == marketItem[i].sold) {
                marketItemsOfAddress[counter] = marketItem[i];
                counter++;
            }
        }
        return marketItemsOfAddress;
    }
    
    function buyPlayer(uint itemId) external botPrevention {
        MarketItem memory marketItem = _getMarketItem(itemId);
        require(marketItem.seller != address(0) && _msgSender() != marketItem.seller && !marketItem.sold, "You can't buy this player");
        require(marketItem.price <= getFootballHeroesToken().balanceOf(_msgSender()), "Balance is too low");
        
        marketItem.owner = _msgSender();
        marketItem.sold = true;
        
        _setMarketItem(marketItem);
        
        getFootballHeroesToken().transferFrom(_msgSender(), address(this), marketItem.price);
        playerContract.transferFrom(address(this), _msgSender(), marketItem.tokenId);
    }
    
}