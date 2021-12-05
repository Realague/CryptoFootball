// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "./StorageHelper.sol";

contract Presale is StorageHelper, ReentrancyGuard {

    uint private endOfPresale;

    bool presaleOpen = false;

    uint private claimAmount = 25;

    uint private tokenUnit = 10**18;

    uint private claimInterval = 14 days;

    uint public firstClaim;

    uint public hardCap = 500 * tokenUnit;

    uint public softCap = 250 * tokenUnit;

    uint public maxContribution = 3 * tokenUnit;

    uint256 public nbTokenAllowed = 100000 * tokenUnit;

    uint public presalePrice;

    constructor(address storageAddress) StorageHelper(storageAddress) {
    }

    // *** Setter Methods **
    function setPresaleOpen(bool _presaleOpen) external onlyOwner {
        presaleOpen = _presaleOpen;
    }

    function setEndOfPresale(uint _endOfPresale) external onlyOwner {
        endOfPresale = _endOfPresale;
    }

    function setClaimAmount(uint _claimAmount) external onlyOwner {
        claimAmount = _claimAmount;
    }

    function setFirstClaim(uint _firstClaim) external onlyOwner {
        firstClaim = _firstClaim;
    }

    function setHardCap(uint _hardCap) external onlyOwner {
        hardCap = _hardCap;
    }

    function setSoftCap(uint _softCap) external onlyOwner {
        softCap = _softCap;
    }

    function setMaxContribution(uint _maxContribution) external onlyOwner {
        maxContribution = _maxContribution;
    }

    function setNbTokenAllowed(uint _nbTokenAllowed) external onlyOwner {
        nbTokenAllowed = _nbTokenAllowed;
    }

    function setPresalePrice(uint _presalePrice) external onlyOwner {
        presalePrice = _presalePrice;
    }

    function getTimeLeft() external view returns (uint) {
        return endOfPresale - block.timestamp;
    }

    function contribute() external payable nonReentrant botPrevention {
        require(presaleOpen && endOfPresale >= block.timestamp, "Presale closed");
        uint currentContribution = _getAddressContribution(_msgSender());
        uint currentTotalContribution = _getTotalContribution();
        require(msg.value + currentTotalContribution <= hardCap, "Presale already soldout");
        require(msg.value + currentContribution <= maxContribution, "Can't exceed max contribution");
        
        _setAddressContribution(_msgSender(), msg.value + currentContribution);
        _setTotalContribution(currentTotalContribution + msg.value);
        _setNumberOfPresaleClaimLeft(_msgSender(), 100 / claimAmount);
    }

    function claim() external nonReentrant botPrevention {
        uint nbClaimLeft = _getNumberOfPresaleClaimLeft(_msgSender());
        uint nextClaimTimestamp = firstClaim + (100 / claimAmount - nbClaimLeft) * claimInterval;
        require(nextClaimTimestamp <= block.timestamp, "Can't claim yet");
        uint nbClaim = (block.timestamp - nextClaimTimestamp) / claimInterval + 1;
        uint amountToClaim = nbClaim * claimAmount * _getAddressContribution(_msgSender()) / 100 * (nbTokenAllowed / hardCap);

        _setNumberOfPresaleClaimLeft(_msgSender(), nbClaimLeft - nbClaim);

        footballHeroesToken.transfer(_msgSender(), amountToClaim);
    }
}