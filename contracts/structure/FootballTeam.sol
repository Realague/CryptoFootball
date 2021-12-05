// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Player.sol";

struct FootballTeam {
    uint composition;
    uint goalKeeper;
    uint[] attackers;
    uint[] midfielders;
    uint[] defenders;
}

struct AiFootballTeam {
    Player goalKeeper;
    Player[] attackers;
    Player[] midfielders;
    Player[] defenders;
    uint rewards;
    uint difficulty;
}

struct Composition {
    uint attackerNb;
    uint midfielderNb;
    uint defenderNb;
}