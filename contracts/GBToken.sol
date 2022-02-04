// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract GBToken is ERC20Burnable, Ownable {

    mapping(address => bool) private blacklistedAddress;

    constructor() ERC20 ("GoldenBall", "GB") {
        _mint(_msgSender(), 1000000 * (10 ** 18));
    }

    function blacklistAddress(address wallet, bool isBlacklisted) external onlyOwner {
        blacklistedAddress[wallet] = isBlacklisted;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklistedAddress[from]);
        super._beforeTokenTransfer(from, to, amount);
    }
    
}