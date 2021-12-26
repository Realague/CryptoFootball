// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
    
struct Player {
    uint id;
    uint imageId;
    Position position;
    Rarity rarity;
    Frame frame;
    uint score;
    uint currentStamina;
    uint lastTraining;
    uint xp;
}

struct OpponentPlayer {
    uint imageId;
    Position position;
    Rarity rarity;
}

enum Frame { NONE, BRONZE, SILVER, GOLD, DIAMOND }

enum Rarity { REGIONAL, NATIONAL, CHAMPION, LEGEND }

enum Position { GOALKEEPER, DEFENDER, MIDFIELDER, ATTACKER }