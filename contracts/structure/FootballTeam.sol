// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Player.sol";

struct FootballTeam {
    uint composition;
    uint goalKeeper;
    uint[] attackers;
    uint[] midfielders;
    uint[] defenders;
    uint currentMatchAvailable;
    uint lastMatchPlayed;
}

struct AiFootballTeam {
    uint goalKeeper;
    uint[] attackers;
    uint[] midfielders;
    uint[] defenders;
    uint rewards;
    uint averageScore;
}

struct Composition {
    uint attackerNb;
    uint midfielderNb;
    uint defenderNb;
}