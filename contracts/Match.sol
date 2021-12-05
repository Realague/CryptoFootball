// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Game.sol";

contract Match is Game {

    Composition[] private compositions;

    AiFootballTeam[] private opponentTeams;

    mapping(address => uint[]) private addressToOpponents;

    uint private opponentsNb = 3;

    constructor(address storageAddress) Game(storageAddress) {
    }

    event MatchResult(
        address indexed _address,
        uint rewards,
        bool won
    );

    modifier validTeam() {
        FootballTeam memory footballTeam = footballHeroesStorage.getFootballTeam(_msgSender());
        require(footballTeam.composition.attackers == footballTeam.attackers.length, "You don't have a complete team yet");
        _;
    }

    // *** Setter Methods ***
    function setCompositions(Composition[] memory _compositions) external onlyOwner {
        delete compositions;
        for (uint i = 0; i != _compositions.length; i++) {
            compositions.push(_compositions[i]);
        }
    }

    function setOpponentsNb(uint _opponentsNb) external onlyOwner {
        opponentsNb = _opponentsNb;
    }

    function addOpponentTeam(AiFootballTeam memory opponentTeam) external onlyOwner {
        opponentTeams.push(opponentTeam);
    }

    function setOpponentTeams(AiFootballTeam[] memory _opponentTeams) external onlyOwner {
        delete opponentTeams;
        for (uint i = 0; i != _opponentTeams.length; i++) {
            opponentTeams.push(_opponentTeams[i]);
        }
    }

    function setTeam(FootballTeam memory footballTeam) external {
        _checkComposition(footballTeam);
        footballHeroesStorage.setFootballTeam(footballTeam, _msgSender());
    }

    function _checkComposition(FootballTeam memory footballTeam) internal view {
        uint goalKeeper = footballTeam.goalKeeper;
        Composition memory composition = compositions[footballTeam.composition];
        uint[] memory attackers = footballTeam.attackers;
        uint[] memory midfielders = footballTeam.midfielders;
        uint[] memory defenders = footballTeam.defenders;
        require(_getPlayer(goalKeeper).position == Position.GOALKEEPER && _getPlayerOwner(goalKeeper) == _msgSender(), "You are not the owner or this player can't have this role");
        require(attackers.length == composition.attackerNb && midfielders.length == composition.midfielderNb && defenders.length == composition.defenderNb, "Wrong composition");
        for (uint i = 0; i != attackers.length; i++) {
            require(_getPlayer(attackers[i]).position == Position.ATTACKER && _getPlayerOwner(attackers[i]) == _msgSender(), "You are not the owner or this player can't have this role");
            for (uint j = 0; j != attackers.length; j++) {
                require(j == i || attackers[i] != attackers[j], "Same players are used multiple times");
            }
        }
        for (uint i = 0; i != midfielders.length; i++) {
            require(_getPlayer(midfielders[i]).position == Position.MIDFIELDER && _getPlayerOwner(midfielders[i]) == _msgSender(), "You are not the owner or this player can't have this role");
            for (uint j = 0; j != midfielders.length; j++) {
                require(j == i || midfielders[i] != midfielders[j], "Same players are used multiple times");
            }
        }
        for (uint i = 0; i != defenders.length; i++) {
            require(_getPlayer(defenders[i]).position == Position.DEFENDER && _getPlayerOwner(defenders[i]) == _msgSender(), "You are not the owner or this player can't have this role");
            for (uint j = 0; j != defenders.length; j++) {
                require(j == i || defenders[i] != defenders[j], "Same players are used multiple times");
            }
        }
    }

    function refreshOpponents() external validTeam returns (uint[] memory) {

    }

    function _refreshOpponents() internal returns (uint[] memory) {
        uint[] memory opponents;
        for (uint i = 0; i != opponentsNb; i++) {
            _randMod(opponentTeams.length);
        }
    }

    function playMatch(uint opponentTeamId) external validTeam {
        AiFootballTeam opponentTeam = opponentTeams[opponentTeamId];
        FootballTeam playerTeam = footballHeroesStorage.getFootballTeam(_msgSender());

    }
}