// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./structure/Player.sol";
import "./ERC721Storage.sol";

contract PlayerFactory is ERC721Storage {
    
    using SafeMath for uint256;
    
    bool[][] private mintablePlayers = [[true], [true], [true], [true]];
    
    uint[] private frames = [35, 65, 90, 98, 100];
    
    uint[] private rarities = [50, 75, 95, 100];
    
    uint[] private scores = [20, 40, 60, 75];
    
    uint[] private staminaRegenPerDay = [60, 80, 100, 120, 140];
    
    uint[] private positions = [15, 45, 75, 100];
    
    uint private modulus = 100;
    
    uint private staminaMax = 100;
    
    uint private scoreThreshold = 20;
    
    bool public mintOpen = false;
    
    uint public mintFees = 40;
    
    uint public mintPrice = 100;
    
    constructor(address storageAdress) ERC721Storage(storageAdress) {
    }
    
    //Setter
    function setStaminaMax(uint _staminaMax) external onlyOwner {
        staminaMax = _staminaMax;
    }
    
    function setMintOpen(bool _mintOpen) external onlyOwner {
        mintOpen = _mintOpen;
    }

    function setFeesToken(address tokenAddress) external onlyOwner {
        feeToken = IERC20(tokenAddress);
    }
    
    function setFeesAmount(uint amount) external onlyOwner {
        mintFees = amount;
    }
    
    function setMintPrice(uint amount) external onlyOwner {
        mintPrice = amount;
    }
    
    function setScoreThreshold(uint _scoreThreshold) external onlyOwner {
        scoreThreshold = _scoreThreshold;
    }
    
    function setFrames(uint[] memory _frames) external onlyOwner {
        frames = _frames;
    }
    
    function setScores(uint[] memory _scores) external onlyOwner {
        scores = _scores;
    }
    
    function setRarities(uint[] memory _rarities) external onlyOwner {
        rarities = _rarities;
    }
    
    function setModulus(uint _modulus) external onlyOwner {
        modulus = _modulus;
    }
    
    function setStaminaRegenPerDay(uint[] memory _staminaRegenPerDay) external onlyOwner {
        staminaRegenPerDay = _staminaRegenPerDay;
    }
    
    function setMintablePlayer(uint rarity, uint imageId, bool mintable) external onlyOwner {
        mintablePlayers[rarity][imageId] = mintable;
    }

    function mintPlayer(uint imageId, uint position, uint frame, uint rarity, uint score, uint _staminaMax, uint _staminaRegenPerDay) external onlyOwner {
        Player memory player = Player(0, imageId, position, rarity, frame, score, staminaMax, _staminaMax, _staminaRegenPerDay, 0, 0);
        player = footballHeroesStorage.createPlayer(player);
        _safeMint(_msgSender(), player.id);
    }
    
    function mintPlayer() external botPrevention {
        require(mintOpen, "Mint not yet open");
        uint mintPriceCalulated = mintPrice.mul(getFootballTokenPrice());
        require(feeToken.balanceOf(_msgSender()) >= mintFees && getFootballHeroesToken().balanceOf(_msgSender()) >= mintPriceCalulated, "Not enought token to mint.");
        feeToken.transferFrom(_msgSender(), _getRewardPoolAddress(), mintFees);
        getFootballHeroesToken().transferFrom(_msgSender(), _getRewardPoolAddress(), mintPriceCalulated);
        Player memory player;
        player.frame = _generateFrame();
        player = _generateRarityAndScore(player);
        player.position = _generatePosition();
        player.imageId = _generateImageId(player.rarity);
        player.staminaMax = staminaMax;
        player.currentStamina = staminaMax;
        player.staminaRegenPerDay = staminaRegenPerDay[player.frame];
        player = footballHeroesStorage.createPlayer(player);
        _safeMint(_msgSender(), player.id);
    }
    
    function _generateFrame() internal view returns (uint) {
        uint frame = _randMod(modulus);
        
        for (uint i = 0; i < frames.length; i++) {
            if (frame <= frames[i]) {
                return i;
            }
        }
        return 0;
    }
    
    function _generateRarityAndScore(Player memory player) internal view returns (Player memory) {
        uint rarity = _randMod(modulus);
        
        for (uint i = 0; i < rarities.length; i++) {
            if (rarity <= rarities[i]) {
                player.rarity = i;
                if (_randMod(2) == 0) {
                    player.score = scores[i].add(scores[i].mul(_randMod(scoreThreshold)).div(100));
                } else {
                    player.score = scores[i].sub(scores[i].mul(_randMod(scoreThreshold)).div(100));
                }
                return player;
            }
        }
        return player;
    }
    
    function _generateImageId(uint rarity) internal view returns (uint) {
        uint imageId;
        do {
           imageId = _randMod(mintablePlayers[rarity].length);
        } while (!mintablePlayers[rarity][imageId]);
        return imageId;
    }
    
    function _generatePosition() internal view returns (uint) {
        uint position = _randMod(modulus);
        
        for (uint i = 0; i < positions.length; i++) {
            if (position <= positions[i]) {
                return i;
            }
        }
        return 2;
    }

}