// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "./interface/IOpenPack.sol";

contract FootballHeroesPack is ERC721, Ownable {

    IOpenPack private playerFactory;

    Pack[] packList;

    uint[] private packPrice = [1.5 * 10**18, 2.25 * 10**18, 3 * 10**18];

    constructor(address _playerFactory) ERC721("FootballheoresPack", "FHP") {
        playerFactory = IOpenPack(_playerFactory);
    }

    function setOpenPack(address _playerFactory) external onlyOwner {
        playerFactory = IOpenPack(_playerFactory);
    }

    function mintPack(uint packType) payable external {
        require(msg.value >= packPrice[packType]);
        packList.push(Pack(packList.length, packType));
        _mint(_msgSender(), packList.length - 1);
    }

    function withdraw(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) > 0);
        token.transfer(_msgSender(), token.balanceOf(address(this)));
    }

    function openPack(uint packId) external {
        require(ownerOf(packId) == _msgSender(), "You don't own this pack");
        _burn(packId);
        playerFactory.openPack(packId);
    }

}
