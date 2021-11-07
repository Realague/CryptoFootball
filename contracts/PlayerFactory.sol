// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol';
import './Player.sol';
import './StorageHelper.sol';

contract PlayerFactory is IERC721, StorageHelper {
    
    using SafeMath for uint256;
    
    string private _name;

    string private _symbol;
    
    constructor() ERC721 ("WON", "WON") {
    }
    
    uint private randNonce = 0;
    
    uint private modulus = 100;
    
    modifier onlyOwnerOf(uint _tokenId) {
        require(msg.sender == _getPlayerOwner(_tokenId));
        _;
    }
    
    function setModulus(uint _modulus) external {
        modulus = _modulus;
    } 
    
    function randMod(uint _modulus) internal returns(uint) {
        randNonce.add(1);
        return uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce))) % _modulus;
    }
    
    function mintPlayer() external returns (Player memory) {
        Player memory player;
        uint rarity = randMod(100);
        //SquidEarnStorage.getUint()
        return player;
    }
    
    function balanceOf(address _owner) external view returns (uint256) {
        return _getNumberOfPlayerOwned(_owner);
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return _getPlayerOwner(_tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        _setNumberOfPlayerOwned(_to, _getNumberOfPlayerOwned(_to).add(1));
        _setNumberOfPlayerOwned(_from, _getNumberOfPlayerOwned(_from).sub(1));
        _setPlayer(_tokenId, _to);
        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require (_getPlayerOwner(_tokenId) == _msgSender() || _getPlayerApproval(_tokenId) == _msgSender());
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external payable onlyOwnerOf(_tokenId) {
        _setPlayerApproval(_tokenId, _approved);
        emit Approval(_msgSender(), _approved, _tokenId);
    }
}