// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./CryptoFootballStorage.sol";
import "./IUniswapV2Pair.sol";

contract StorageHelper is Ownable {
        
    using SafeMath for uint256;
    
    uint private randNonce = 0;
    
    CryptoFootballStorage internal cryptoFootballStorage;
    
    constructor(address storageAdress) {
        cryptoFootballStorage = CryptoFootballStorage(storageAdress);
    }
    
    modifier botPrevention() {
        require(_msgSender() == tx.origin);
        _;
    }
    
    modifier onlyOwnerOf(uint _tokenId) {
        require(_msgSender() == _getPlayerOwner(_tokenId));
        _;
    }
    
    function _setPlayer(uint _tokenId, address _owner) internal {
        address from = _getPlayerOwner(_tokenId);
        if (from != address(0)) {
            _setNumberOfPlayerOwned(from, _getNumberOfPlayerOwned(from).sub(1));
        }
        cryptoFootballStorage.setAddress(keccak256(abi.encodePacked("player", _tokenId)), _owner);
        _setNumberOfPlayerOwned(_owner, _getNumberOfPlayerOwned(_owner).add(1));
    }
    
    function setCryptoFootballToken(address _tokenAddress) external onlyOwner {
        cryptoFootballStorage.setCryptoFootballToken(_tokenAddress);
    }
    
    function getCryptoFootballToken() internal view returns (IERC20) {
        return cryptoFootballStorage.getCryptoFootballToken();
    }
    
    function setCryptoFootballStorage(address _cryptoFootballStorage) external {
        cryptoFootballStorage = CryptoFootballStorage(_cryptoFootballStorage);
    }
    
    function _getPlayer(uint _tokenId) internal view returns (Player memory) {
        return cryptoFootballStorage.getPlayer(_tokenId);
    }
    
    function _getPlayerOwner(uint _tokenId) internal view returns (address) {
        return cryptoFootballStorage.getAddress(keccak256(abi.encodePacked("player", _tokenId)));
    }
    
    function _deletePlayerowner(uint _tokenId) internal {
        return cryptoFootballStorage.deleteAddress(keccak256(abi.encodePacked("player", _tokenId)));
    }
    
    function _setMarketplaceAddress(address _contractAddress) internal {
        cryptoFootballStorage.setAddress(keccak256("marketplace"), _contractAddress);
    }
    
    function _getMarketplaceAdress() internal view returns (address contractAddress) {
        return cryptoFootballStorage.getAddress(keccak256("marketplace"));
    }
    
    function _setNumberOfPlayerOwned(address _address, uint _count) internal {
        cryptoFootballStorage.setUint(keccak256(abi.encodePacked("nbplayers", _address)), _count);
    }
    
    function _getNumberOfPlayerOwned(address _address) internal view returns (uint) {
        return cryptoFootballStorage.getUint(keccak256(abi.encodePacked("nbplayers", _address)));
    }
    
    function _setPlayerApproval(uint _tokenId, address _address) internal {
        cryptoFootballStorage.setAddress(keccak256(abi.encodePacked("playerapproval", _tokenId)), _address);
    }
    
    function _getPlayerApproval(uint _tokenId) internal view returns (address) {
        return cryptoFootballStorage.getAddress(keccak256(abi.encodePacked("playerapproval", _tokenId)));
    }
        
    function _setOperatorApproval(uint _tokenId, address _address) internal {
        cryptoFootballStorage.setAddress(keccak256(abi.encodePacked("operatorapproval", _tokenId)), _address);
    }
    
    function _getOperatorApproval(uint _tokenId) internal view returns (address) {
        return cryptoFootballStorage.getAddress(keccak256(abi.encodePacked("operatorapproval", _tokenId)));
    }
    
    function _getRewards(address _address) internal view returns (uint) {
        return cryptoFootballStorage.getUint(keccak256(abi.encodePacked("rewards", _address)));
    }
    
    function _setRewards(address _address, uint _rewardTimer) internal {
        cryptoFootballStorage.setUint(keccak256(abi.encodePacked("rewardtimer", _address)), _rewardTimer);
    }
    
    function _getRewardTimer(address _address) internal view returns (uint) {
        return cryptoFootballStorage.getUint(keccak256(abi.encodePacked("rewardtimer", _address)));
    }
    
    function _setRewardTimer(address _address) internal {
        cryptoFootballStorage.setUint(keccak256(abi.encodePacked("rewardtimer", _address)), block.timestamp);
    }
    
    function _getClaimCooldown(address _address) internal view returns (uint) {
        return cryptoFootballStorage.getUint(keccak256(abi.encodePacked("claimtimer", _address)));
    }
    
    function _setClaimCooldown(address _address, uint _coolDownTimer) internal {
        cryptoFootballStorage.setUint(keccak256(abi.encodePacked("claimtimer", _address)), _coolDownTimer);
    }
    
    function _getGlobalRewards() internal view returns (uint) {
        return cryptoFootballStorage.getUint(keccak256(abi.encodePacked("globalrewards")));
    } 
    
    function _addGlobalRewards(uint _rewards) internal {
        cryptoFootballStorage.setUint(keccak256(abi.encodePacked("globalrewards")), cryptoFootballStorage.getUint(keccak256(abi.encodePacked("globalrewards"))).add(_rewards));
    }
    
    function _removeGlobalRewards(uint _rewards) internal {
        cryptoFootballStorage.setUint(keccak256(abi.encodePacked("globalrewards")), cryptoFootballStorage.getUint(keccak256(abi.encodePacked("globalrewards"))).sub(_rewards));
    }
    
    function getPairAddress() public view onlyOwner returns (address) {
        return cryptoFootballStorage.getAddress(keccak256(abi.encodePacked("pairaddress")));
    }
    
    function setPairAddress(address _pairAddress) external onlyOwner {
        cryptoFootballStorage.setAddress(keccak256(abi.encodePacked("pairaddress")), _pairAddress);
    }
    
    function _getRewardPoolAddress() internal view returns (address) {
        return cryptoFootballStorage.getAddress(keccak256(abi.encodePacked("rewardpool")));
    }
    
    function _setRewardPoolAddress(address _rewardPoolAddress) internal {
        cryptoFootballStorage.setAddress(keccak256(abi.encodePacked("rewardpool")), _rewardPoolAddress);
    }
    
    function _addMarketItems(MarketItem memory marketItem) internal {
        cryptoFootballStorage.addMarketItems(marketItem);
    }
    
    function _setMarketItem(MarketItem memory marketItem) internal {
        cryptoFootballStorage.setMarketItem(marketItem);
    }
    
    function _getMarketItem(uint itemId) internal view returns (MarketItem memory) {
        return cryptoFootballStorage.getMarketItem(itemId);
    }
    
    function _getMarketItems() internal view returns (MarketItem[] memory) {
        return cryptoFootballStorage.getMarketItems();
    }
    
    function _getNumberMarketItems() internal view returns (uint) {
        return cryptoFootballStorage.getNumberMarketItems();
    }

    function _randMod(uint _modulus) internal view returns (uint) {
        randNonce.add(1);
        return uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce))) % _modulus;
    }
    
    function getFootballTokenPrice() public view returns (uint) {
        return _getTokenPrice(getPairAddress());
    }
    
    function _getTokenPrice(address _pairAddress) private view returns (uint)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);
        (uint nbToken1, uint nbToken2,) = pair.getReserves();
        return nbToken2.div(nbToken1);
   }
   
   function withdraw(address tokenAddress) external onlyOwner {
       IERC20 token = IERC20(tokenAddress);
       require(token.balanceOf(address(this)) > 0);
       token.transfer(_msgSender(), token.balanceOf(address(this)));
   }
}