// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Game.sol";

contract Match is Game {

    Composition[] private compositions;

    OpponentPlayer[] private opponentPlayers;

    AiFootballTeam[] private opponentTeams;

    uint[] private nbMatchByFrame = [1, 2, 3, 4, 5];

    mapping(address => uint[]) private addressToOpponents;

    uint private opponentsNb = 3;

    uint private refreshOpponentsFee = 5;

    constructor(address storageAddress) Game(storageAddress) {
    }

    event MatchResult(
        address indexed _address,
        uint rewards,
        bool won,
        uint opponentGoal,
        uint teamGoal
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

    function deleteOpponentTeam(uint index) external onlyOwner {
        if (index >= opponentTeams.length) return;

        for (uint i = index; i < opponentTeams.length - 1; i++){
            opponentTeams[i] = opponentTeams[i + 1];
        }
        delete opponentTeams[opponentTeams.length - 1];
    }

    function addOpponentTeam(OpponentPlayer memory goalKeeper, OpponentPlayer[] memory defenders, OpponentPlayer[] memory midfielders, OpponentPlayer[] memory attackers, uint rewards, uint averageScore) external onlyOwner {
        _setMappings(goalKeeper, defenders, midfielders, attackers, rewards, averageScore);
    }

    function _setMappings(OpponentPlayer memory goalKeeper, OpponentPlayer[] memory defenders, OpponentPlayer[] memory midfielders, OpponentPlayer[] memory attackers, uint rewards, uint averageScore) internal {
        AiFootballTeam memory footballTeam;
        footballTeam.averageScore = averageScore;
        footballTeam.rewards = rewards;
        footballTeam.goalKeeper = opponentPlayers.length;
        opponentPlayers.push(goalKeeper);
        uint[] memory players = new uint[](defenders.length);
        for (uint i = 0; i != defenders.length; i++) {
            players[players.length] = opponentPlayers.length;
            opponentPlayers.push(defenders[i]);
            
        }
        footballTeam.defenders = players;
        delete players;
        for (uint i = 0; i != midfielders.length; i++) {
            players[players.length] = opponentPlayers.length;
            opponentPlayers.push(midfielders[i]);
        }
        footballTeam.defenders = players;
        delete players;
        for (uint i = 0; i != attackers.length; i++) {
            players[players.length] = opponentPlayers.length;
            opponentPlayers.push(attackers[i]);
        }
        footballTeam.defenders = players;
        opponentTeams.push(footballTeam);
    }

    function setPlayerTeam(FootballTeam memory footballTeam) external {
        _checkComposition(footballTeam);
        footballTeam.lastMatchPlayed = footballHeroesStorage.getFootballTeam(_msgSender()).lastMatchPlayed;
        if (footballTeam.lastMatchPlayed == 0) {
            footballTeam.currentMatchAvailable = nbMatchByFrame[uint(_calculateAverageFrame(footballTeam))];
        }
        footballHeroesStorage.setFootballTeam(footballTeam, _msgSender());
        if (addressToOpponents[_msgSender()].length == 0) {
            addressToOpponents[_msgSender()] = _refreshOpponents();
        }
    }

    function getPlayerTeam() external view returns (FootballTeam memory) {
        return footballHeroesStorage.getFootballTeam(_msgSender());
    }

    function getOpponentPlayer(uint index) external view returns (OpponentPlayer memory) {
        return opponentPlayers[index];
    }

    function getOpponentTeam(uint id) external view returns (AiFootballTeam memory) {
        return opponentTeams[id];
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

    function getCurrentMatchAvailable() external view returns (uint) {
        return _getCurrentMatchAvailable(footballHeroesStorage.getFootballTeam(_msgSender()));
    }

    function _getCurrentMatchAvailable(FootballTeam memory footballTeam) internal view returns (uint) {
        uint maxMatch = nbMatchByFrame[uint(_calculateAverageFrame(footballTeam))];
        if (footballTeam.lastMatchPlayed == 0) {
            return footballTeam.currentMatchAvailable;
        }
        uint currentMatchAvailable = footballTeam.currentMatchAvailable + (footballTeam.lastMatchPlayed - block.timestamp) / (maxMatch / 24 hours);
        return currentMatchAvailable > maxMatch ? maxMatch : currentMatchAvailable;
    }

    function playMatch(uint opponentTeamId) external validTeam {
        AiFootballTeam storage opponentTeam = opponentTeams[opponentTeamId];
        FootballTeam memory playerTeam = footballHeroesStorage.getFootballTeam(_msgSender());
        uint availableMatch = _getCurrentMatchAvailable(playerTeam);
        require(availableMatch >= 1, "You already played all your matches today");
        uint footballTeamAverageScore = _calculateAverageScore(playerTeam);
        int scoreDifference = int(footballTeamAverageScore - opponentTeam.averageScore);
        bool win = int(_randMod(100)) < (50 + scoreDifference * (1 / (scoreDifference / 100 + 1)));
        
        uint rewards;
        if (win) {
            rewards = opponentTeam.rewards * getFootballTokenPrice();
            require(_checkPoolToken(rewards));
            _addGlobalRewards(rewards);
            _setRewards(_msgSender(), _getRewards(_msgSender()) + rewards);
        }
        playerTeam.currentMatchAvailable = availableMatch - 1;
        playerTeam.lastMatchPlayed = block.timestamp;
        footballHeroesStorage.setFootballTeam(playerTeam, _msgSender());
        uint maxGoal = 1;
        int score = scoreDifference;
        if (score < 0) {
            score = score - score - score;
        }
        if (score > 3) {
            maxGoal = uint(scoreDifference) / 3;
        }
        if (score > 20) {
            maxGoal = uint(scoreDifference) / 5;
        }
        if (score > 40) {
            maxGoal = uint(scoreDifference) / 7;
        }
        uint teamGoal;
        uint opponentGoal;
        if (win) {
            teamGoal = _randMod(maxGoal) + 1;
            opponentGoal = _randMod(teamGoal - 1);
        } else {
            opponentGoal = _randMod(maxGoal) + 1;
            teamGoal = _randMod(opponentGoal - 1);
        }

        emit MatchResult(_msgSender(), rewards, win, opponentGoal, teamGoal);
    }

    function _calculateAverageScore(FootballTeam memory team) internal view returns (uint) {
        uint totalScore = 0;
        totalScore += _getPlayer(team.goalKeeper).score;
        for (uint i = 0; i != team.attackers.length; i++) {
            totalScore += _getPlayer(team.attackers[i]).score;
        }
        for (uint i = 0; i != team.midfielders.length; i++) {
            totalScore += _getPlayer(team.midfielders[i]).score;
        }
        for (uint i = 0; i != team.defenders.length; i++) {
            totalScore += _getPlayer(team.defenders[i]).score;
        }
        return totalScore / (team.defenders.length + team.attackers.length + team.midfielders.length + 1);
    }

    function _calculateAverageFrame(FootballTeam memory team) internal view returns (Frame) {
        uint totalScore = 0;
        totalScore += uint(_getPlayer(team.goalKeeper).frame);
        for (uint i = 0; i != team.attackers.length; i++) {
            totalScore += uint(_getPlayer(team.attackers[i]).frame);
        }
        for (uint i = 0; i != team.midfielders.length; i++) {
            totalScore += uint(_getPlayer(team.midfielders[i]).frame);
        }
        for (uint i = 0; i != team.defenders.length; i++) {
            totalScore += uint(_getPlayer(team.defenders[i]).frame);
        }
        return Frame(totalScore / (team.defenders.length + team.attackers.length + team.midfielders.length + 1));
    }
}