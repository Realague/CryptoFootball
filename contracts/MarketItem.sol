// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct MarketItem {
    uint itemId;
    uint256 tokenId;
    address seller;
    address owner;
    uint256 price;
    bool sold;
}