// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./FootballHeroesStorage.sol";
import "./interface/IUniswapV2Pair.sol";

contract StorageHelper is Ownable {
        
    using SafeMath for uint256;
    
    uint private randNonce = 0;

    uint internal MAX_INT = 2**256 - 1;
    
    FootballHeroesStorage internal footballHeroesStorage;

    IERC20 internal feeToken;

    IERC20 internal footballHeroesToken;
    
    constructor(address storageAdress) {
        footballHeroesStorage = FootballHeroesStorage(storageAdress);
        feeToken = footballHeroesStorage.getFeeToken();
        footballHeroesToken = footballHeroesStorage.getFootballHeroesToken();
    }
    
    modifier botPrevention() {
        require(_msgSender() == tx.origin);
        _;
    }
    
    modifier onlyOwnerOf(uint tokenId) {
        require(_msgSender() == _getPlayerOwner(tokenId));
        _;
    }

    modifier checkBalanceAndAllowance(IERC20 token, uint amount) {
        require(token.allowance(_msgSender(), address(this)) >= amount, "Insuficient allowance");
        require(token.balanceOf(_msgSender()) >= amount, "Insuficient balance");
        _;
    }
    
    function _setPlayer(uint _tokenId, address _owner) internal {
        address from = _getPlayerOwner(_tokenId);
        if (from != address(0)) {
            _setNumberOfPlayerOwned(from, _getNumberOfPlayerOwned(from).sub(1));
        }
        footballHeroesStorage.setAddress(keccak256(abi.encodePacked("player", _tokenId)), _owner);
        _setNumberOfPlayerOwned(_owner, _getNumberOfPlayerOwned(_owner).add(1));
    }
    
    function _getPlayer(uint _tokenId) internal view returns (Player memory) {
        return footballHeroesStorage.getPlayer(_tokenId);
    }
    
    function _getPlayerOwner(uint _tokenId) internal view returns (address) {
        return footballHeroesStorage.getAddress(keccak256(abi.encodePacked("player", _tokenId)));
    }
    
    function _deletePlayerOwner(uint _tokenId) internal {
        footballHeroesStorage.deleteAddress(keccak256(abi.encodePacked("player", _tokenId)));
    }

    function _setTotalContribution(uint _contribution) internal {
        footballHeroesStorage.setUint(keccak256("totalcontribution"), _contribution);
    }
    
    function _getTotalContribution() internal view returns (uint) {
        return footballHeroesStorage.getUint(keccak256("totalcontribution"));
    }
    
    function _setAddressContribution(address _address, uint _contribution) internal {
        footballHeroesStorage.setUint(keccak256(abi.encodePacked("contribution", _address)), _contribution);
    }
    
    function _getAddressContribution(address _address) internal view returns (uint) {
        return footballHeroesStorage.getUint(keccak256(abi.encodePacked("contribution", _address)));
    }

    function _setNumberOfPresaleClaimLeft(address _address, uint _nbClaimLeft) internal {
        footballHeroesStorage.setUint(keccak256(abi.encodePacked("nbclaim", _address)), _nbClaimLeft);
    }
    
    function _getNumberOfPresaleClaimLeft(address _address) internal view returns (uint) {
        return footballHeroesStorage.getUint(keccak256(abi.encodePacked("nbclaim", _address)));
    }

    function _setNumberOfPlayerOwned(address _address, uint _count) internal {
        footballHeroesStorage.setUint(keccak256(abi.encodePacked("nbplayers", _address)), _count);
    }
    
    function _getNumberOfPlayerOwned(address _address) internal view returns (uint) {
        return footballHeroesStorage.getUint(keccak256(abi.encodePacked("nbplayers", _address)));
    }
    
    function _setPlayerApproval(uint _tokenId, address _address) internal {
        footballHeroesStorage.setAddress(keccak256(abi.encodePacked("playerapproval", _tokenId)), _address);
    }
    
    function _getPlayerApproval(uint _tokenId) internal view returns (address) {
        return footballHeroesStorage.getAddress(keccak256(abi.encodePacked("playerapproval", _tokenId)));
    }
    
    function _getRewards(address _address) internal view returns (uint) {
        return footballHeroesStorage.getUint(keccak256(abi.encodePacked("rewards", _address)));
    }
    
    function _setRewards(address _address, uint _rewards) internal {
        footballHeroesStorage.setUint(keccak256(abi.encodePacked("rewards", _address)), _rewards);
    }
    
    function _getRewardTimer(address _address) internal view returns (uint) {
        return footballHeroesStorage.getUint(keccak256(abi.encodePacked("rewardtimer", _address)));
    }
    
    function _setRewardTimer(address _address) internal {
        footballHeroesStorage.setUint(keccak256(abi.encodePacked("rewardtimer", _address)), block.timestamp);
    }
    
    function _getClaimCooldown(address _address) internal view returns (uint) {
        return footballHeroesStorage.getUint(keccak256(abi.encodePacked("claimtimer", _address)));
    }
    
    function _setClaimCooldown(address _address, uint _coolDownTimer) internal {
        footballHeroesStorage.setUint(keccak256(abi.encodePacked("claimtimer", _address)), _coolDownTimer);
    }
    
    function _getGlobalRewards() internal view returns (uint) {
        return footballHeroesStorage.getUint(keccak256(abi.encodePacked("globalrewards")));
    } 
    
    function _addGlobalRewards(uint _rewards) internal {
        footballHeroesStorage.setUint(keccak256("globalrewards"), footballHeroesStorage.getUint(keccak256(abi.encodePacked("globalrewards"))).add(_rewards));
    }
    
    function _removeGlobalRewards(uint _rewards) internal {
        footballHeroesStorage.setUint(keccak256("globalrewards"), footballHeroesStorage.getUint(keccak256(abi.encodePacked("globalrewards"))).sub(_rewards));
    }
    
    function _getPairAddress() internal view returns (address) {
        return footballHeroesStorage.getAddress(keccak256("pairaddress"));
    }
    
    function setPairAddress(address _pairAddress) external onlyOwner {
        footballHeroesStorage.setAddress(keccak256("pairaddress"), _pairAddress);
    }
    
    function _addMarketItem(MarketItem memory marketItem) internal {
        footballHeroesStorage.addMarketItems(marketItem);
    }
    
    function _setMarketItem(MarketItem memory marketItem) internal {
        footballHeroesStorage.setMarketItem(marketItem);
    }
    
    function _getMarketItem(uint itemId) internal view returns (MarketItem memory) {
        return footballHeroesStorage.getMarketItem(itemId);
    }
    
    function _getMarketItems() internal view returns (MarketItem[] memory) {
        return footballHeroesStorage.getMarketItems();
    }
    
    function _getNumberMarketItems() internal view returns (uint) {
        return footballHeroesStorage.getNumberMarketItems();
    }

    function _randMod(uint _modulus) internal view returns (uint) {
        randNonce.add(1);
        return uint(keccak256(abi.encodePacked(_msgSender(), randNonce))) % _modulus;
    }
    
    function getFootballTokenPrice() public view returns (uint) {
        return _getTokenPrice(_getPairAddress());
    }
    
    function _getTokenPrice(address _pairAddress) private view returns (uint) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);
        (uint nbToken1, uint nbToken2,) = pair.getReserves();
        return nbToken2.div(nbToken1);
   }

    function _getXpRequireToLvlUp(uint score) internal pure returns (uint) {
        return score * (score / 2);
    }
   
   function withdraw(address tokenAddress) external onlyOwner {
       IERC20 token = IERC20(tokenAddress);
       require(token.balanceOf(address(this)) > 0);
       token.transfer(_msgSender(), token.balanceOf(address(this)));
   }
}