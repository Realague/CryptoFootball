// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
    
struct Player {
    uint id;
    uint imageId;
    Rarity rarity;
    Frame frame;
    uint score;
    uint staminaMax;
    uint currentStamina;
    uint lastTimePlayed;
    uint xp;
}

enum Frame { NONE, BRONZE, SILVER, GOLD, DIAMOND }

enum Rarity { REGIONAL, NATIONAL, CHAMPION, LEGEND }