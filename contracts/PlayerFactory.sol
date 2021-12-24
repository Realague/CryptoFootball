// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./ERC721Storage.sol";
import "./interface/IUniswapV2Router.sol";

contract PlayerFactory is ERC721Storage {
    
    using SafeMath for uint256;

    bool[][4][4] private mintablePlayers;
    
    uint[] private frames = [35, 65, 90, 98, 100];
    
    uint[] private rarities = [50, 75, 95, 100];
    
    uint[] private scores = [20, 40, 60, 75];
    
    uint[] private positions = [15, 45, 75, 100];

    IUniswapV2Router router = IUniswapV2Router(address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3));

    uint private liquidity = 5 * 10 ** 18;
    
    uint private modulus = 100;
    
    uint private staminaMax = 100;
    
    uint private scoreThreshold = 20;
    
    bool public mintOpen = true;
    
    uint public mintFees = 45 * 10 ** 18;
    
    uint public mintPrice = 100 * 10 ** 18;

    event NewPlayer(address indexed owner, uint indexed playerId);
    
    constructor(address storageAddress) ERC721Storage(storageAddress) {
        feeToken.approve(address(router), MAX_INT);
        footballHeroesToken.approve(address(router), MAX_INT);
        
        mintablePlayers[0][0] = [true, true];
        mintablePlayers[0][1] = [true, true, true];
        mintablePlayers[0][2] = [true, true];
        mintablePlayers[0][3] = [true, true, true];

        mintablePlayers[1][0] = [true, true, true, true];
        mintablePlayers[1][1] = [true, true, true, true, true];
        mintablePlayers[1][2] = [true, true, true, true, true, true];
        mintablePlayers[1][3] = [true, true, true, true];

        mintablePlayers[2][0] = [true, true, true, true, true];
        mintablePlayers[2][1] = [true, true, true, true, true, true];
        mintablePlayers[2][2] = [true, true, true, true, true];
        mintablePlayers[2][3] = [true, true, true, true, true, true];

        mintablePlayers[3][0] = [true, true, true, true, true, true, true, true];
        mintablePlayers[3][1] = [true, true, true, true, true, true];
        mintablePlayers[3][2] = [true, true, true, true, true, true];
        mintablePlayers[3][3] = [true, true, true, true, true];
    }
    
    //Setter
    function setLiquidity(uint _liquidity) external onlyOwner {
        liquidity = _liquidity;
    }

    function setMintOpen(bool _mintOpen) external onlyOwner {
        mintOpen = _mintOpen;
    }
    
    function setFeesAmount(uint amount) external onlyOwner {
        mintFees = amount * 10**18;
    }
    
    function setMintPrice(uint amount) external onlyOwner {
        mintPrice = amount * 10**18;
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
    
    function setMintablePlayer(uint rarity, uint position, uint imageId, bool mintable) external onlyOwner {
        mintablePlayers[rarity][position][imageId] = mintable;
    }

    function setMintablePlayers(uint rarity, uint position, bool[] memory mintables) external onlyOwner {
        mintablePlayers[rarity][position] = mintables;
    }

    function mintPlayer(uint imageId, Position position, Frame frame, Rarity rarity, uint score) external onlyOwner {
        Player memory player = Player(0, imageId, position, rarity, frame, score, staminaMax, 0, 0);
        player = footballHeroesStorage.createPlayer(player);
        _safeMint(_msgSender(), player.id);
        emit NewPlayer(_msgSender(), player.id);
    }
    
    function mintPlayer() external botPrevention checkBalanceAndAllowance(feeToken, mintFees) checkBalanceAndAllowance(footballHeroesToken, mintPrice * getFootballTokenPrice()) {
        require(mintOpen, "Mint not yet open");
        uint mintPriceCalculated = mintPrice * getFootballTokenPrice();
        uint liquidityCalculated = liquidity * getFootballTokenPrice();

        Player memory player;
        player.frame = _generateFrame();
        (player.rarity, player.score) = _generateRarityAndScore();
        player.position = _generatePosition();
        player.imageId = _generateImageId(player.rarity, player.position);
        player.currentStamina = staminaMax;
        player = footballHeroesStorage.createPlayer(player);
        _safeMint(_msgSender(), player.id);


        feeToken.transferFrom(_msgSender(), address(this), mintFees);
        footballHeroesToken.transferFrom(_msgSender(), _getRewardPoolAddress(), mintPriceCalculated - liquidityCalculated);
        footballHeroesToken.transferFrom(_msgSender(), address(this), liquidityCalculated);
        //router.addLiquidity(address(feeToken), address(footballHeroesToken), liquidity, liquidityCalculated, liquidity, liquidityCalculated, _getPairAddress(), block.timestamp + 2 minutes);
        emit NewPlayer(_msgSender(), player.id);
    }
    
    function _generateFrame() internal view returns (Frame) {
        uint frame = _randMod(modulus);
        
        for (uint i = 0; i != frames.length; i++) {
            if (frame <= frames[i]) {
                return Frame(i);
            }
        }
        return Frame(0);
    }
    
    function _generateRarityAndScore() internal view returns (Rarity rarity, uint score) {
        uint rand = _randMod(modulus);
        
        for (uint i = 0; i != rarities.length; i++) {
            if (rand <= rarities[i]) {
                rarity = Rarity(i);
                if (_randMod(2) == 0) {
                    score = scores[i] + scores[i] * _randMod(scoreThreshold) / 100;
                } else {
                    score = scores[i] - scores[i] * _randMod(scoreThreshold) / 100;
                }
            }
        }
    }
    
    function _generateImageId(Rarity rarity, Position position) internal view returns (uint imageId) {
        do {
           imageId = _randMod(mintablePlayers[uint(position)][uint(rarity)].length);
        } while (!mintablePlayers[uint(position)][uint(rarity)][imageId]);
    }
    
    function _generatePosition() internal view returns (Position) {
        uint position = _randMod(modulus);
        
        for (uint i = 0; i != positions.length; i++) {
            if (position <= positions[i]) {
                return Position(i);
            }
        }
        return Position(2);
    }

    function authorizeMarketplace(address marketplaceAddress) external onlyOwner {
        footballHeroesStorage.setOperatorApproval(address(footballHeroesStorage), marketplaceAddress, true);
    }

}