// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "./StorageHelper.sol";
import "./structure/TrainingGround.sol";
import "./structure/Player.sol";
import "./ERC721Storage.sol";
import "./GBToken.sol";

contract Game is StorageHelper, ReentrancyGuard {
    
    using SafeMath for uint256;
    
    uint private claimCooldown = 1 days;
    
    uint private claimFeePercentage = 30;
    
    uint private claimFeeDecreaseRatePerDay = 2;
    
    uint private staminaCost = 20;

    uint private upgradeFrameFee = 10;

    uint private staminaMax = 100;

    uint[] private frameBonus = [0, 10, 20, 30, 50];

    uint[] private staminaRegenPerDay = [60, 80, 100, 120, 140];
    
    TrainingGround[] private trainingGrounds;
    
    bool public trainingOpen = true;
    
    event TrainingDone(address indexed user, bool won, uint rewards, uint xp, bool levelUp);

    event ClaimReward(address indexed user, uint amount);
    
    constructor(address storageAddress) StorageHelper(storageAddress) {
        trainingGrounds.push(TrainingGround(0, 80, 5, 30, 100));
        trainingGrounds.push(TrainingGround(1, 60, 20, 7, 150));
        trainingGrounds.push(TrainingGround(2, 50, 10, 10, 200));
    }
    
    // *** Getter Methods ***
    function getTrainingGrounds() external view onlyOwner returns (TrainingGround[] memory) {
        return trainingGrounds;
    }
    
    function getClaimFeeDecreaseRatePerDay() external view onlyOwner returns (uint) {
        return claimFeeDecreaseRatePerDay;
    }
    
    function getClaimFeePercentage() external view onlyOwner returns (uint) {
        return claimFeePercentage;
    }
    
    function getRewards() public view returns (uint) {
        return _getRewards(_msgSender());
    }
    
    function getClaimFee() public view returns (uint) {
        int fee = int(claimFeePercentage) - int(claimFeeDecreaseRatePerDay) * (int(int(block.timestamp) - int(_getRewardTimer(_msgSender()))) / 1 days);
        return fee > 0 && fee <= 30 ? uint(fee) : 0;
    }
   
    function getClaimCooldown() external view onlyOwner returns (uint) {
        return claimCooldown;
    }
    
    function getCurrentStamina(uint playerId) public view returns (uint) {
        return _getCurrentStamina(_getPlayer(playerId));
    }

    function _getCurrentStamina(Player memory player) internal view returns (uint) {
        if (player.lastTraining == 0) {
            return player.currentStamina;
        }
        uint stamina = player.currentStamina + (block.timestamp - player.lastTraining) / 1 hours * (staminaRegenPerDay[uint(player.frame)] / 24);
        return stamina > staminaMax ? staminaMax : stamina;
    }
    
    function getXpRequireToLvlUp(uint score) internal pure returns (uint) {
        return score * (score / 2);
    }

    function getRemainingClaimCooldown() external view returns (uint) {
        int remainingCooldown = int(_getClaimCooldown(_msgSender())) - int(block.timestamp);
        return remainingCooldown > int(0) ? uint(remainingCooldown) : 0;
    }
    
    // *** Setter Methods **
    function setStaminaMax(uint _staminaMax) external onlyOwner {
        staminaMax = _staminaMax;
    }

    function setStaminaRegenPerDay(uint[] memory _staminaRegenPerDay) external onlyOwner {
        staminaRegenPerDay = _staminaRegenPerDay;
    }


    
    function setTrainingOpen(bool _trainingOpen) external onlyOwner {
        trainingOpen = _trainingOpen;
    }
    
   function setClaimCooldown(uint _claimCooldown) external onlyOwner {
       claimCooldown = _claimCooldown;
   }
    
    function setClaimFeePercentage(uint _claimFeePercentage) external onlyOwner {
        claimFeePercentage = _claimFeePercentage;
    }
    
    function setClaimFeeDecreaseRatePerDay(uint _claimFeeDecreaseRatePerDay) external onlyOwner {
        claimFeeDecreaseRatePerDay = _claimFeeDecreaseRatePerDay;
    }
    
    function setTrainingGround(TrainingGround[] memory _trainingGrounds) external onlyOwner {
        for (uint i = 0; i < trainingGrounds.length; i++) {
            delete trainingGrounds[i];
        }
        for (uint i = 0; i < _trainingGrounds.length; i++) {
            trainingGrounds.push(_trainingGrounds[i]);
        }
    }

    function trainingGround(uint trainingGroundId, uint playerId) external botPrevention onlyOwnerOf(playerId) {
        require(trainingOpen, "Training is closed");
        Player memory player = _getPlayer(playerId);
        require(_getCurrentStamina(player) >= 20, "not enought stamina");
        player.currentStamina = getCurrentStamina(player.id) - 20;
        player.lastTraining = block.timestamp;
        //Create cooldowns for this address if it doesn't exist
        _initCooldowns();
        //Retreiving data for training
        TrainingGround memory tg = trainingGrounds[trainingGroundId];
        uint xpGain;
        bool won = _train(trainingGroundId, player.score);
        //Do the training
        if (won) {
            xpGain += tg.xpGain + tg.xpGain * frameBonus[uint(player.frame)] / 100;
            uint rewards = (tg.rewards + tg.rewards * frameBonus[uint(player.frame)] / 100) * getFootballTokenPrice();
            require(_checkPoolToken(rewards));
            _addGlobalRewards(rewards);
            _setRewards(_msgSender(), _getRewards(_msgSender()) + rewards);
        } else {
            xpGain = tg.xpGain / 2;
        }
        
        //Limit score to 100
        if (player.score == 100) {
            xpGain = 0;
        }
        player.xp += xpGain;
        bool levelUp = false;
        //check if the player levelUp
        if (player.xp >= getXpRequireToLvlUp(player.score)) {
            player.score += 1;
            player.xp %= getXpRequireToLvlUp(player.score);
            levelUp = true;
        }
        footballHeroesStorage.setPlayer(player);

        emit TrainingDone(_msgSender(), won, won ? tg.rewards : 0, xpGain, levelUp);
    }
    
    function _initCooldowns() internal {
        if (_getRewardTimer(_msgSender()) == 0) {
            _setRewardTimer(_msgSender());
        }
        if (_getClaimCooldown(_msgSender()) == 0) {
            _setClaimCooldown(_msgSender(), block.timestamp.add(claimCooldown));
        }
    }
    
    function _train(uint trainingGroundId, uint playerScore) internal view returns (bool) {
        return _randMod(100) <= trainingGrounds[trainingGroundId].difficulty * playerScore / 100 + trainingGrounds[trainingGroundId].baseWinrate;
    }
    
    function _checkPoolToken(uint rewards) internal view returns (bool) {
        return int(footballHeroesToken.balanceOf(address(footballHeroesStorage)) - _getGlobalRewards()) >= int(rewards);
    }
    
    function claimReward() external nonReentrant botPrevention {
        require(_getClaimCooldown(_msgSender()) <= block.timestamp && trainingOpen);
        uint initialRewards = _getRewards(_msgSender());
        uint rewards = initialRewards.sub(getClaimFee().mul(initialRewards).div(100));
        _removeGlobalRewards(rewards);
        _setRewards(_msgSender(), 0);
        _setClaimCooldown(_msgSender(), block.timestamp.add(claimCooldown));
        _setRewardTimer(_msgSender());
        footballHeroesStorage.claimRewards(_msgSender(), rewards);

        emit ClaimReward(_msgSender(), rewards);
    }

}