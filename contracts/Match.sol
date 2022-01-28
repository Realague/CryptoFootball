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

    uint public refreshOpponentsFee = 5;

    bool public isMatchOpen = true;

    constructor(address storageAddress) Game(storageAddress) {
    }

    event MatchResult(
        address indexed _address,
        uint rewards,
        bool won,
        int scoreDifference
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

    function setMatchOpen(bool isOpen) external onlyOwner {
        isMatchOpen = isOpen;
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

    function setPlayerTeam(FootballTeam memory footballTeam) external {
        _checkComposition(footballTeam);
        //_setTeamPlayersStatus(footballHeroesStorage.getFootballTeam(_msgSender()), true);
        footballTeam.lastMatchPlayed = footballHeroesStorage.getFootballTeam(_msgSender()).lastMatchPlayed;
        if (footballTeam.lastMatchPlayed == 0) {
            footballTeam.currentMatchAvailable = nbMatchByFrame[uint(_calculateAverageFrame(footballTeam))];
        }
        footballHeroesStorage.setFootballTeam(footballTeam, _msgSender());
        //_setTeamPlayersStatus(footballTeam, false);
        /*if (footballHeroesStorage.getOpponentTeams(_msgSender()).length == 0) {
            footballHeroesStorage.setOpponentTeams(_refreshOpponents(), _msgSender());
        }*/
        if (addressToOpponents[_msgSender()].length == 0) {
            addressToOpponents[_msgSender()] = _refreshOpponents();
        }
    }

    /*function _setTeamPlayersStatus(FootballTeam memory footballTeam, bool status) internal {
        Player memory player = _getPlayer(footballTeam.goalKeeper);
        player.isAvailable = status;
        footballHeroesStorage.setPlayer(player);
        for (uint i = 0; i != footballTeam.attackers.length; i++) {
            player = _getPlayer(footballTeam.attackers[i]);
            player.isAvailable = status;
            footballHeroesStorage.setPlayer(player);
        }
        for (uint i = 0; i != footballTeam.midfielders.length; i++) {
            player = _getPlayer(footballTeam.midfielders[i]);
            player.isAvailable = status;
            footballHeroesStorage.setPlayer(player);
        }
        for (uint i = 0; i != footballTeam.defenders.length; i++) {
            player = _getPlayer(footballTeam.defenders[i]);
            player.isAvailable = status;
            footballHeroesStorage.setPlayer(player);
        }
    }*/

    function getPlayerTeam() external view returns (FootballTeam memory) {
        return footballHeroesStorage.getFootballTeam(_msgSender());
    }

    function getOpponentPlayer(uint index) external view returns (OpponentPlayer memory) {
        return opponentPlayers[index];
    }

    function getCompositions() external view returns (Composition[] memory) {
        return compositions;
    }

    function getComposition(uint id) external view returns (Composition memory) {
        return compositions[id];
    }

    function getOpponentTeam(uint id) external view returns (AiFootballTeam memory) {
        return opponentTeams[id];
    }

    function getOpponentTeams() external view returns (uint[] memory) {
        return addressToOpponents[_msgSender()];
    }

    function refreshOpponents() external validTeam checkBalanceAndAllowance(footballHeroesToken, getFootballTokenPrice() * refreshOpponentsFee) {
        require(isMatchOpen, "Match are not opened yet");
        addressToOpponents[_msgSender()] = _refreshOpponents();
        footballHeroesToken.transferFrom(_msgSender(), address(this), getFootballTokenPrice() * refreshOpponentsFee);
    }

    function getCurrentMatchAvailable() external view returns (uint) {
        return _getCurrentMatchAvailable(footballHeroesStorage.getFootballTeam(_msgSender()));
    }

    function playMatch(uint opponentTeamId) external validTeam {
        require(isMatchOpen, "Match are not opened yet");
        require(contains(addressToOpponents[_msgSender()], opponentTeamId), "Cannot play match against this opponent");
        AiFootballTeam storage opponentTeam = opponentTeams[opponentTeamId];
        FootballTeam memory playerTeam = footballHeroesStorage.getFootballTeam(_msgSender());
        uint availableMatch = 1;//_getCurrentMatchAvailable(playerTeam);
        require(availableMatch >= 1, "You already played all your matches today");
        //uint footballTeamAverageScore = _calculateAverageScore(playerTeam);
        int scoreDifference = 1;//int(footballTeamAverageScore - opponentTeam.averageScore);
        bool win = true;//int(_randMod(100)) < (50 + scoreDifference * (1 / (scoreDifference / 100 + 1)));
        
        uint rewards;
        if (win) {
            rewards = opponentTeam.rewards * getFootballTokenPrice();
            require(_checkPoolToken(rewards), "Not enought token in the reward pool");
            _addGlobalRewards(rewards);
            _setRewards(_msgSender(), _getRewards(_msgSender()) + rewards);
        }
        playerTeam.currentMatchAvailable = availableMatch - 1;
        playerTeam.lastMatchPlayed = block.timestamp;
        footballHeroesStorage.setFootballTeam(playerTeam, _msgSender());

        emit MatchResult(_msgSender(), rewards, win, scoreDifference);
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

    function _getCurrentMatchAvailable(FootballTeam memory footballTeam) internal view returns (uint) {
        uint maxMatch = nbMatchByFrame[uint(_calculateAverageFrame(footballTeam))];
        if (footballTeam.lastMatchPlayed == 0) {
            return footballTeam.currentMatchAvailable;
        }
        uint currentMatchAvailable = footballTeam.currentMatchAvailable + (block.timestamp - footballTeam.lastMatchPlayed) / 1 hours * (maxMatch / 24);
        return currentMatchAvailable > maxMatch ? maxMatch : currentMatchAvailable;
    }

    function contains(uint[] memory array, uint value) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function _refreshOpponents() internal view returns (uint[] memory) {
        uint[] memory opponents = new uint[](opponentsNb);
        for (uint i = 0; i != opponentsNb; i++) {
            opponents[i] = _randMod(opponentTeams.length);
        }
        return opponents;
    }

    function _checkComposition(FootballTeam memory footballTeam) internal view {
        Composition memory composition = compositions[footballTeam.composition];
        require(composition.attackerNb != 0 && _getPlayer(footballTeam.goalKeeper).position == Position.GOALKEEPER && _getPlayerOwner(footballTeam.goalKeeper) == _msgSender(), "You are not the owner or this player can't have this role");
        require(footballTeam.attackers.length == composition.attackerNb && footballTeam.midfielders.length == composition.midfielderNb && footballTeam.defenders.length == composition.defenderNb, "Wrong composition");
        for (uint i = 0; i != footballTeam.attackers.length; i++) {
            require(_getPlayer(footballTeam.attackers[i]).position == Position.ATTACKER && _getPlayerOwner(footballTeam.attackers[i]) == _msgSender(), "You are not the owner or this player can't have this role");
            for (uint j = 0; j != footballTeam.attackers.length; j++) {
                require(j == i || footballTeam.attackers[i] != footballTeam.attackers[j], "Same players are used multiple times");
            }
        }
        for (uint i = 0; i != footballTeam.midfielders.length; i++) {
            require(_getPlayer(footballTeam.midfielders[i]).position == Position.MIDFIELDER && _getPlayerOwner(footballTeam.midfielders[i]) == _msgSender(), "You are not the owner or this player can't have this role");
            for (uint j = 0; j != footballTeam.midfielders.length; j++) {
                require(j == i || footballTeam.midfielders[i] != footballTeam.midfielders[j], "Same players are used multiple times");
            }
        }
        for (uint i = 0; i != footballTeam.defenders.length; i++) {
            require(_getPlayer(footballTeam.defenders[i]).position == Position.DEFENDER && _getPlayerOwner(footballTeam.defenders[i]) == _msgSender(), "You are not the owner or this player can't have this role");
            for (uint j = 0; j != footballTeam.defenders.length; j++) {
                require(j == i || footballTeam.defenders[i] != footballTeam.defenders[j], "Same players are used multiple times");
            }
        }
    }

    function _setMappings(OpponentPlayer memory goalKeeper, OpponentPlayer[] memory defenders, OpponentPlayer[] memory midfielders, OpponentPlayer[] memory attackers, uint rewards, uint averageScore) internal {
        AiFootballTeam memory footballTeam;
        footballTeam.averageScore = averageScore;
        footballTeam.rewards = reward;
        footballTeam.goalKeeper = opponentPlayers.length;
        opponentPlayers.push(goalKeeper);
        footballTeam.defenders = new uint[](defenders.length);
        footballTeam.midfielders = new uint[](midfielders.length);
        footballTeam.attackers = new uint[](attackers.length);
        for (uint i = 0; i != defenders.length; i++) {
            footballTeam.defenders[i] = opponentPlayers.length;
            opponentPlayers.push(defenders[i]);
        }
        for (uint i = 0; i != midfielders.length; i++) {
            footballTeam.midfielders[i] = opponentPlayers.length;
            opponentPlayers.push(midfielders[i]);
        }
        for (uint i = 0; i != attackers.length; i++) {
            footballTeam.attackers[i] = opponentPlayers.length;
            opponentPlayers.push(attackers[i]);
        }
        opponentTeams.push(footballTeam);
    }
}