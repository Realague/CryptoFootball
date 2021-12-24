// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Game.sol";

contract Match is Game {

    Composition[] private compositions;

    AiFootballTeam[] private opponentTeams;

    mapping(address => uint[]) private addressToOpponents;

    uint private opponentsNb = 3;

    uint private refreshOpponentsFee = 5;

    constructor(address storageAddress) Game(storageAddress) {
    }

    event MatchResult(
        address indexed _address,
        uint rewards,
        bool won
    );

    modifier validTeam() {
        FootballTeam memory footballTeam = footballHeroesStorage.getFootballTeam(_msgSender());
        require(compositions[footballTeam.composition].attackerNb == footballTeam.attackers.length, "You don't have a complete team yet");
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
        opponentTeam.averageScore = _calculateAverageScore(opponentTeam.attackers, opponentTeam.midfielders, opponentTeam.defenders, opponentTeam.goalKeeper);
         //opponentTeams.push(opponentTeam);
    }

    function setOpponentTeams(AiFootballTeam[] memory _opponentTeams) external onlyOwner {
        delete opponentTeams;
        for (uint i = 0; i != _opponentTeams.length; i++) {
            opponentTeams[i].averageScore = _calculateAverageScore(opponentTeams[i].attackers, opponentTeams[i].midfielders, opponentTeams[i].defenders, opponentTeams[i].goalKeeper);
            opponentTeams.push(OpponentPlayer(opponentTeams[i].goalKeeper, opponentTeams[i].attackers, opponentTeams[i].midfielders,
            opponentTeams[i].defenders, opponentTeams[i].rewards, opponentTeams[i].difficulty, opponentTeams[i].averageScore));
        }
    }

    function setTeam(FootballTeam memory footballTeam) external {
        _checkComposition(footballTeam);
        if (footballHeroesStorage.getFootballTeam(_msgSender()).lastMatchPlayed == 0) {

        }
        footballHeroesStorage.setFootballTeam(footballTeam, _msgSender());
        if (addressToOpponents[_msgSender()].length == 0) {
            addressToOpponents[_msgSender()] = _refreshOpponents();
        }
    }

    function _checkComposition(FootballTeam memory footballTeam) internal view {
        uint goalKeeper = footballTeam.goalKeeper;
        Composition memory composition = compositions[footballTeam.composition];
        uint[] memory attackers = footballTeam.attackers;
        uint[] memory midfielders = footballTeam.midfielders;
        uint[] memory defenders = footballTeam.defenders;
        require(composition.attackerNb != 0 && _getPlayer(goalKeeper).position == Position.GOALKEEPER && _getPlayerOwner(goalKeeper) == _msgSender(), "You are not the owner or this player can't have this role");
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

    function refreshOpponents() external validTeam checkBalanceAndAllowance(footballHeroesToken, getFootballTokenPrice() * refreshOpponentsFee) {
        addressToOpponents[_msgSender()] = _refreshOpponents();
        footballHeroesToken.transferFrom(_msgSender(), address(this), getFootballTokenPrice() * refreshOpponentsFee);
    }

    function _refreshOpponents() internal view returns (uint[] memory) {
        uint[] memory opponents;
        for (uint i = 0; i != opponentsNb; i++) {
            opponents[i] = _randMod(opponentTeams.length);
        }
        return opponents;
    }

    function playMatch(uint opponentTeamId) external validTeam {
        AiFootballTeam memory opponentTeam = opponentTeams[opponentTeamId];
        FootballTeam memory playerTeam = footballHeroesStorage.getFootballTeam(_msgSender());
        //uint footballTeamAverageScore = _calculateAverageScore(playerTeam.attackers, playerTeam.midfielders, playerTeam.defenders, playerTeam.goalKeeper);
        bool win = _randMod(100) >= 1;
        uint rewards;
        if (win) {
            rewards = opponentTeam.rewards * getFootballTokenPrice();
            require(_checkPoolToken(rewards));
            _addGlobalRewards(rewards);
            _setRewards(_msgSender(), _getRewards(_msgSender()) + rewards);
        }

        
    }

    function _calculateAverageScore(uint[] memory attackers, uint[] memory midfielders, uint[] memory defenders, uint goalKeeper) internal view returns (uint) {
        uint totalScore = 0;
        totalScore += _getPlayer(goalKeeper).score;
        for (uint i = 0; i != attackers.length; i++) {
            totalScore += _getPlayer(attackers[i]).score;
        }
        for (uint i = 0; i != midfielders.length; i++) {
            totalScore += _getPlayer(midfielders[i]).score;
        }
        for (uint i = 0; i != defenders.length; i++) {
            totalScore += _getPlayer(defenders[i]).score;
        }
        return totalScore / (defenders.length + attackers.length + midfielders.length + 1);
    }

    function _calculateAverageScore(OpponentPlayer[] memory attackers, OpponentPlayer[] memory midfielders, OpponentPlayer[] memory defenders, OpponentPlayer memory goalKeeper) internal pure returns (uint) {
        uint totalScore = 0;
        totalScore += goalKeeper.score;
        for (uint i = 0; i != attackers.length; i++) {
            totalScore += attackers[i].score;
        }
        for (uint i = 0; i != midfielders.length; i++) {
            totalScore += midfielders[i].score;
        }
        for (uint i = 0; i != defenders.length; i++) {
            totalScore += defenders[i].score;
        }
        return totalScore / (defenders.length + attackers.length + midfielders.length + 1);
    }

    function _calculateAverageFrame(uint[] memory attackers, uint[] memory midfielders, uint[] memory defenders, uint goalKeeper) internal view returns (Frame) {
        uint totalScore = 0;
        totalScore += uint(_getPlayer(goalKeeper).frame);
        for (uint i = 0; i != attackers.length; i++) {
            totalScore += uint(_getPlayer(attackers[i]).frame);
        }
        for (uint i = 0; i != midfielders.length; i++) {
            totalScore += uint(_getPlayer(midfielders[i]).frame);
        }
        for (uint i = 0; i != defenders.length; i++) {
            totalScore += uint(_getPlayer(defenders[i]).frame);
        }
        return Frame(totalScore / (defenders.length + attackers.length + midfielders.length + 1));
    }
}