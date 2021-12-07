// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./ERC721Storage.sol";
import "./interface/IUniswapV2Router.sol";

contract PlayerFactory is ERC721Storage {
    
    using SafeMath for uint256;

    bool[][][] private mintablePlayers = [[[true], [true], [true], [true]], [[true], [true], [true], [true]], [[true], [true], [true], [true]], [[true], [true], [true], [true]]];
    
    uint[] private frames = [35, 65, 90, 98, 100];
    
    uint[] private rarities = [50, 75, 95, 100];
    
    uint[] private scores = [20, 40, 60, 75];
    
    uint[] private staminaRegenPerDay = [60, 80, 100, 120, 140];
    
    uint[] private positions = [15, 45, 75, 100];

    IUniswapV2Router router = IUniswapV2Router(address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3));

    uint private liquidity = 5;
    
    uint private modulus = 100;
    
    uint private staminaMax = 100;
    
    uint private scoreThreshold = 20;
    
    bool public mintOpen = false;
    
    uint public mintFees = 45;
    
    uint public mintPrice = 100;
    
    constructor(address storageAdress) ERC721Storage(storageAdress) {
        feeToken.approve(address(router), MAX_INT);
        footballHeroesToken.approve(address(router), MAX_INT);
    }
    
    //Setter
    function setLiquidity(uint _liquidity) external onlyOwner {
        liquidity = _liquidity;
    }

    function setStaminaMax(uint _staminaMax) external onlyOwner {
        staminaMax = _staminaMax;
    }
    
    function setMintOpen(bool _mintOpen) external onlyOwner {
        mintOpen = _mintOpen;
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
    
    function setStaminaRegenPerDay(uint[] memory _staminaRegenPerDay) external onlyOwner {
        staminaRegenPerDay = _staminaRegenPerDay;
    }
    
    function setMintablePlayer(uint rarity, uint position, uint imageId, bool mintable) external onlyOwner {
        mintablePlayers[rarity][position][imageId] = mintable;
    }

    function setMintablePlayers(uint rarity, uint position, bool[] memory mintables) external onlyOwner {
        mintablePlayers[rarity][position] = mintables;
    }

    function mintPlayer(uint imageId, Position position, Frame frame, Rarity rarity, uint score, uint _staminaMax, uint _staminaRegenPerDay) external onlyOwner {
        Player memory player = Player(0, imageId, position, rarity, frame, score, staminaMax, _staminaMax, _staminaRegenPerDay, 0, 0);
        player = footballHeroesStorage.createPlayer(player);
        _safeMint(_msgSender(), player.id);
    }
    
    function mintPlayer() external botPrevention checkBalanceAndAllowance(feeToken, mintFees) checkBalanceAndAllowance(footballHeroesToken, mintPrice * getFootballTokenPrice()) {
        require(mintOpen, "Mint not yet open");
        uint mintPriceCalulated = mintPrice.mul(getFootballTokenPrice());

        Player memory player;
        player.frame = _generateFrame();
        player = _generateRarityAndScore(player);
        player.position = _generatePosition();
        player.imageId = _generateImageId(player.rarity, player.position);
        player.staminaMax = staminaMax;
        player.currentStamina = staminaMax;
        player.staminaRegenPerDay = staminaRegenPerDay[uint(player.frame)];
        player = footballHeroesStorage.createPlayer(player);
        _safeMint(_msgSender(), player.id);

        feeToken.transferFrom(_msgSender(), _getRewardPoolAddress(), mintFees);
        footballHeroesToken.transferFrom(_msgSender(), _getRewardPoolAddress(), mintPriceCalulated * 100 / (100 + liquidity));
        footballHeroesToken.transferFrom(_msgSender(), address(this), mintPriceCalulated * liquidity / 100);
        router.addLiquidity(address(feeToken), address(footballHeroesToken), liquidity, getFootballTokenPrice() * liquidity, liquidity, getFootballTokenPrice() * liquidity, _getPairAddress(), block.timestamp + 2 minutes);
    }
    
    function _generateFrame() internal view returns (Frame) {
        uint frame = _randMod(modulus);
        
        for (uint i = 0; i < frames.length; i++) {
            if (frame <= frames[i]) {
                return Frame(i);
            }
        }
        return Frame(0);
    }
    
    function _generateRarityAndScore(Player memory player) internal view returns (Player memory) {
        uint rarity = _randMod(modulus);
        
        for (uint i = 0; i < rarities.length; i++) {
            if (rarity <= rarities[i]) {
                player.rarity = Rarity(i);
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
    
    function _generateImageId(Rarity rarity, Position position) internal view returns (uint) {
        uint imageId;
        do {
           imageId = _randMod(mintablePlayers[uint(rarity)][uint(position)].length);
        } while (!mintablePlayers[uint(rarity)][uint(position)][imageId]);
        return imageId;
    }
    
    function _generatePosition() internal view returns (Position) {
        uint position = _randMod(modulus);
        
        for (uint i = 0; i < positions.length; i++) {
            if (position <= positions[i]) {
                return Position(i);
            }
        }
        return Position(2);
    }

}