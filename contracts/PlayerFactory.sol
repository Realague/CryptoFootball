// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./ERC721Storage.sol";

contract PlayerFactory is ERC721Storage {
    
    using SafeMath for uint256;

    bool[][4][4] private mintablePlayers;
    
    uint[] private frames = [35, 65, 90, 98, 100];
    
    uint[] private rarities = [50, 75, 95, 100];
    
    uint[] private scores = [20, 40, 60, 75];
    
    uint[] private positions = [15, 45, 75, 100];

    uint private xpPerDollar = 50;

    uint private upgradeFrameFee = 10 ** 18;
    
    uint private modulus = 100;
    
    uint private staminaMax = 100;
    
    uint private scoreThreshold = 20;

    uint[] private upgradeFrameCost = [5 ** 18, 10 ** 18, 15 ** 18, 20 ** 18, 30 ** 18];
    
    bool public mintOpen = true;

    bool public levelUpOpen = true;

    bool public upgradeFrameOpen = true;

    uint public mintFees = 45 * 10 ** 18;
    
    uint public mintPrice = 100 * 10 ** 18;

    event UpgradeFrame(address indexed user, uint indexed playerId);

    event LevelUp(address indexed user, uint indexed playerId, uint xpGain, uint levelGain);

    event NewPlayer(address indexed owner, uint indexed playerId);
    
    constructor(address storageAddress) ERC721Storage(storageAddress) {
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
    function setLevelUpOpen(bool _levelUpOpen) external onlyOwner {
        levelUpOpen = _levelUpOpen;
    }

    function setUpgradeFrameOpen(bool _upgradeFrameOpen) external onlyOwner {
        upgradeFrameOpen = _upgradeFrameOpen;
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

    function setXpPerDollar(uint _xpPerDollar) external onlyOwner {
        xpPerDollar = _xpPerDollar;
    }

    function setUpgradeFrameFee(uint _upgradeFrameFee) external onlyOwner {
        upgradeFrameFee = _upgradeFrameFee * 10**18;
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

        Player memory player;
        player.frame = _generateFrame();
        (player.rarity, player.score) = _generateRarityAndScore();
        player.position = _generatePosition();
        player.imageId = _generateImageId(player.rarity, player.position);
        player.currentStamina = staminaMax;
        //player.isAvailable = true;
        player = footballHeroesStorage.createPlayer(player);
        _safeMint(_msgSender(), player.id);

        feeToken.transferFrom(_msgSender(), address(this), mintFees);
        footballHeroesToken.transferFrom(_msgSender(), address(footballHeroesStorage), mintPriceCalculated);
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

        function payToLevelUp(uint playerId, uint amount) external botPrevention onlyOwnerOf(playerId) checkBalanceAndAllowance(footballHeroesToken, amount * getFootballTokenPrice())  {
        Player memory player = _getPlayer(playerId);
        //require(player.isAvailable, "Can't level up a player that is in a team");
        uint xp = amount * getFootballTokenPrice() * xpPerDollar;
        uint xpGain = xp;
        uint levelGain = 0;
        while (_getXpRequireToLvlUp(player.score) - player.xp <= xp) {
            xp -= (_getXpRequireToLvlUp(player.score) - player.xp);
            player.score++;
            player.xp = 0;
            levelGain++;
        }
        player.xp += xp;
        footballHeroesStorage.setPlayer(player);

        footballHeroesToken.transferFrom(_msgSender(), address(this), amount * getFootballTokenPrice());

        emit LevelUp(_msgSender(), playerId, xpGain, levelGain);
    }

    function upgradeFrame(uint playerId1, uint playerId2) external botPrevention onlyOwnerOf(playerId1) onlyOwnerOf(playerId2) checkBalanceAndAllowance(feeToken, upgradeFrameFee)
    checkBalanceAndAllowance(footballHeroesToken, upgradeFrameCost[uint(_getPlayer(playerId1).frame)] * getFootballTokenPrice()) {
        require(upgradeFrameOpen, "Upgrade frame not yet open");
        Player memory player1 = _getPlayer(playerId1);
        Player memory player2 = _getPlayer(playerId2);
        //require(player2.isAvailable, "Can't burn a player that is in a team");
        uint upgradeCost = upgradeFrameCost[uint(player1.frame)] * getFootballTokenPrice();

        require(isApprovedForAll(_msgSender(), address(this)), "Insuficient allowance");
        require(player1.frame == player2.frame && player1.imageId == player2.imageId && player1.frame != Frame.DIAMOND, "Both players need to be identical");

        uint frame = uint(player1.frame);
        if (player1.frame <= Frame.SILVER && _randMod(100) >= 3) {
            frame += 1;
        }
        frame += 1;
        player1.frame = Frame(frame);
        player1.score = (player1.score + player2.score) / 2;
        footballHeroesStorage.setPlayer(player1);

        burn(player2.id);

        feeToken.transferFrom(_msgSender(), address(this), upgradeFrameFee);
        footballHeroesToken.transferFrom(_msgSender(), address(footballHeroesStorage), upgradeCost);

        emit UpgradeFrame(_msgSender(), player1.id);
    }

    function authorizeMarketplace(address marketplaceAddress) external onlyOwner {
        footballHeroesStorage.setOperatorApproval(address(footballHeroesStorage), marketplaceAddress, true);
    }

}