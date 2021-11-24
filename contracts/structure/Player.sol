// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
    
struct Player {
    uint id;
    uint imageId;
    uint position;
    uint rarity;
    uint frame;
    uint score;
    uint staminaMax;
    uint staminaRegenPerDay;
    uint currentStamina;
    uint lastTraining;
    uint xp;
}

enum Frame { NONE, BRONZE, SILVER, GOLD, DIAMOND }

enum Rarity { REGIONAL, NATIONAL, CHAMPION, LEGEND }

enum Position { GOAL, DEFENDER, MIDFIELDER, ATTACKER }