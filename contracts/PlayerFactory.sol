// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./Player.sol";
import "./ERC721Storage.sol";

contract PlayerFactory is ERC721Storage {
    
    using SafeMath for uint256;
    
    bool[][] private mintablePlayers = [[true], [true], [true], [true]];
    
    uint[] private frames = [35, 65, 90, 98, 100];
    
    uint[] private rarities = [50, 75, 95, 100];
    
    uint[] private scores = [20, 40, 60, 75];
    
    uint[] private stamina = [2, 3, 5, 7];
    
    IERC20 private feeToken = IERC20(address(0x0078867bbeef44f2326bf8ddd1941a4439382ef2a7));
    
    uint private mintPrice = 100;
    
    uint private modulus = 100;
    
    uint private scoreThreshold = 20;
    
    uint public mintFees = 40;
    
    constructor(address storageAdress) ERC721Storage(storageAdress) {
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
    
    function setStamina(uint[] memory _stamina) external onlyOwner {
        stamina = _stamina;
    }
    
    function setMintablePlayer(uint rarity, uint imageId, bool mintable) external {
        mintablePlayers[rarity][imageId] = mintable;
    }

    function mintPlayer(uint imageId, uint frame, uint rarity, uint score, uint staminaMax) external onlyOwner {
        Player memory player = Player(0, imageId, rarity, frame, score, staminaMax, staminaMax, 0, 0);
        player = cryptoFootballStorage.createPlayer(player);
        _safeMint(_msgSender(), player.id);
    }
    
    function mintPlayer() external {
        uint mintPriceCalulated = mintPrice.mul(getFootballTokenPrice());
        require(feeToken.balanceOf(_msgSender()) >= mintFees && getCryptoFootballToken().balanceOf(_msgSender()) >= mintPriceCalulated, "Not enought token to mint.");
        feeToken.transferFrom(_msgSender(), address(this), mintFees);
        getCryptoFootballToken().transferFrom(_msgSender(), address(this), mintPriceCalulated);
        Player memory player;
        player = _generateFrame(player);
        player = _generateRarityAndScore(player);
        player.imageId = _generateImageId(player.rarity);
        player.xp = 0;
        player = cryptoFootballStorage.createPlayer(player);
        _safeMint(_msgSender(), player.id);
    }
    
    function _generateFrame(Player memory player) internal view returns (Player memory) {
        uint frame = _randMod(modulus);
        
        for (uint i = 0; i < frames.length; i++) {
            if (frame <= frames[i]) {
                player.frame =  i;
                return player;
            }
        }
        return player;
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
                player.staminaMax = stamina[i];
                player.currentStamina = stamina[i];
                player.lastTraining = 0;
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


}