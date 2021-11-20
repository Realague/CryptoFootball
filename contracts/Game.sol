// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "./StorageHelper.sol";
import "./TrainingGround.sol";
import "./Player.sol";

contract Game is StorageHelper, ReentrancyGuard {
    
    using SafeMath for uint256;
    
    uint private claimCooldown = 1 days;
    
    uint private claimFeePercentage = 30;
    
    uint private claimFeeDecreaseRatePerDay = 2;
    
    uint private staminaCost = 20;
    
    bool private fightOpen = false;
    
    uint[] private frameBonus = [0, 10, 20, 30, 50];
    
    uint[] private staminaRegenPerDay = [60, 80, 100, 120, 140];
    
    TrainingGround[] private trainingGrounds;
    
    event TrainingDone(bool won, uint rewards, uint xp, bool levelUp);
    
    constructor(address storageAddress) StorageHelper(storageAddress) {
        trainingGrounds.push(TrainingGround(0, 80, 5, 30, 100));
        trainingGrounds.push(TrainingGround(1, 60, 20, 7, 150));
        trainingGrounds.push(TrainingGround(2, 50, 10, 10, 200));
    }
    
    function setTrainingGround(TrainingGround[] memory _trainingGrounds) external onlyOwner {
        for (uint i = 0; i < trainingGrounds.length; i++) {
            delete trainingGrounds[i];
        }
        for (uint i = 0; i < _trainingGrounds.length; i++) {
            trainingGrounds.push(_trainingGrounds[i]);
        }
    }
    
    function getTrainingGrounds() external view onlyOwner returns (TrainingGround[] memory) {
        return trainingGrounds;
    }
    
   function setClaimCooldown(uint _claimCooldown) external onlyOwner {
       claimCooldown = _claimCooldown;
   }
   
   function getClaimCooldown() external view onlyOwner returns (uint) {
       return claimCooldown;
   }
    
    function setOpenFight(bool _fightOpen) external onlyOwner {
        fightOpen = _fightOpen;
    }
    
    function getOpenFight() external view onlyOwner returns (bool) {
       return fightOpen;
   }
    
    function setClaimFeePercentage(uint _claimFeePercentage) external onlyOwner {
        claimFeePercentage = _claimFeePercentage;
    }
    
    function getClaimFeePercentage() external view onlyOwner returns (uint) {
        return claimFeePercentage;
    }
    
    function setClaimFeeDecreaseRatePerDay(uint _claimFeeDecreaseRatePerDay) external onlyOwner {
        claimFeeDecreaseRatePerDay = _claimFeeDecreaseRatePerDay;
    }
    
    function getClaimFeeDecreaseRatePerDay() external view onlyOwner returns (uint) {
        return claimFeeDecreaseRatePerDay;
    }

    function trainingGround(uint trainingGroundId, uint playerId) external botPrevention {
        require(fightOpen);
        Player memory player = _getPlayer(playerId);
        require(getCurrentStamina(player) >= 20, "not enought stamina");
        player.currentStamina = getCurrentStamina(player) - 20;
        //Create cooldowns for this address if it doesn't exist
        _initCooldowns();
        //Retreiving data for training
        TrainingGround memory tg = trainingGrounds[trainingGroundId];
        uint xpGain;
        bool won;
        //Do the training
        if (_train(trainingGroundId, player.score)) {
            xpGain += tg.xpGain + tg.xpGain * frameBonus[player.frame] / 100;
            uint rewards = (tg.rewards + tg.rewards * frameBonus[player.frame] / 100) / getFootballTokenPrice();
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
        if (player.xp >= xpRequireToLvlUp(player.score)) {
            player.score += 1;
            player.xp %= xpRequireToLvlUp(player.score);
            levelUp = true;
        }
        cryptoFootballStorage.setPlayer(player);
        emit TrainingDone(won, won ? tg.rewards : 0, xpGain, levelUp);
    }
    
    function getCurrentStamina(Player memory player) public view returns (uint) {
        uint stamina = player.currentStamina + (player.lastTraining - block.timestamp) / (staminaRegenPerDay[player.frame] / 24 hours);
        return stamina > player.staminaMax ? player.staminaMax : stamina;
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
    
    function xpRequireToLvlUp(uint score) public pure returns (uint) {
        return score * (score / 2);
    }
    
    function _checkPoolToken(uint rewards) internal view returns (bool) {
        return getCryptoFootballToken().balanceOf(address(this)) - _getGlobalRewards() >= rewards;
    }
    
    function claimReward() external nonReentrant botPrevention {
        require(_getClaimCooldown(_msgSender()) >= block.timestamp);
        uint initialRewards = _getRewards(_msgSender());
        uint rewards = initialRewards.sub(getClaimFee().mul(initialRewards).div(100));
        _removeGlobalRewards(initialRewards);
        _setRewards(_msgSender(), 0);
        _setClaimCooldown(_msgSender(), block.timestamp.add(claimCooldown));
        _setRewardTimer(_msgSender());
        getCryptoFootballToken().transfer(_msgSender(), rewards);
    }
    
    function burnRewardToIncreaseScore(uint tokenId, uint amountToBurn) external botPrevention {
        
    }
    
    function getRewards() public view returns (uint) {
        return _getRewards(_msgSender());
    }
    
    function getClaimFee() public view returns (uint) {
        uint fee = claimFeePercentage.sub(claimFeeDecreaseRatePerDay.mul(block.timestamp.sub(_getRewardTimer(_msgSender())).div(1 days)));
        return fee > 0 && fee <= 30 ? fee : 0;
    }
    
}

