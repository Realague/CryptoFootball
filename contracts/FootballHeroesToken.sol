// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract FootballHeroes is ERC20Burnable {

    constructor() ERC20 ("FootballHeroes", "FH") {
        _mint(_msgSender(), 1000000 * (10 ** 18));
    }
    
}