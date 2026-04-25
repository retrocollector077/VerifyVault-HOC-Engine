// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC721} from "openzeppelin-upgradeable/interfaces/IERC721Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "openzeppelin-upgradeable/interfaces/IERC20Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

contract NFTStaking is ReentrancyGuardUpgradeable, Initializable, OwnableUpgradeable {
    IERC721 public nft;
    IERC20 public rewardToken;
    address public feeRecipient;
    uint256 public rewardRatePerDay; // tokens per day per NFT

    uint256 public stakingFeePercent; // e.g., 100 = 1%
    uint256 public unstakingFeePercent; // e.g., 50 = 0.5%

    struct StakeInfo {
        address staker;
        uint256 tokenId;
        uint256 stakeTimestamp;
        uint256 nftValue; // value at stake time for reward calc
    }

    mapping(uint256 => StakeInfo) public stakes;

    event Staked(address indexed staker, uint256 tokenId, uint256 timestamp);
    event Unstaked(address indexed staker, uint256 tokenId, uint256 reward, uint256 fee);
    event FeeRecipientUpdated(address newFeeRecipient);
    event FeesUpdated(uint256 stakingFeePercent, uint256 unstakingFeePercent);
    event RewardRateUpdated(uint256 newRate);

    function initialize(
        address _nft,
        address _rewardToken,
        address _feeRecipient,
        uint256 _rewardRatePerDay,
        uint256 _stakingFeePercent,
        uint256 _unstakingFeePercent
    ) public initializer {
        __ReentrancyGuardUpgradeable_init();
        __OwnableUpgradeable_init();
        nft = IERC721(_nft);
        rewardToken = IERC20(_rewardToken);
        feeRecipient = _feeRecipient;
        rewardRatePerDay = _rewardRatePerDay;
        stakingFeePercent = _stakingFeePercent;
        unstakingFeePercent = _unstakingFeePercent;
    }

    function stake(uint256 tokenId, uint256 nftValue) external payable nonReentrant {
        // Calculate staking fee
        uint256 fee = (msg.value * stakingFeePercent) / 10000; // feePercent scaled by 10000
        if (fee > 0) {
            payable(feeRecipient).transfer(fee);
        }

        nft.transferFrom(msg.sender, address(this), tokenId);
        stakes[tokenId] = StakeInfo(msg.sender, tokenId, block.timestamp, nftValue);
        emit Staked(msg.sender, tokenId, block.timestamp);
    }

    function unstake(uint256 tokenId) external nonReentrant {
        StakeInfo memory info = stakes[tokenId];
        require(info.staker == msg.sender, "Not staker");

        uint256 stakingDuration = block.timestamp - info.stakeTimestamp;
        uint256 daysStaked = stakingDuration / 1 days;

        uint256 rewardAmount = daysStaked * rewardRatePerDay * info.nftValue / 1e18; // scaled

        // Calculate unstaking fee
        uint256 feeAmount = (rewardAmount * unstakingFeePercent) / 10000;

        // Transfer reward tokens minus fee
        if (rewardAmount > 0) {
            uint256 rewardAfterFee = rewardAmount - feeAmount;
            if (rewardAfterFee > 0) {
                rewardToken.transfer(msg.sender, rewardAfterFee);
            }
            if (feeAmount > 0) {
                rewardToken.transfer(feeRecipient, feeAmount);
            }
        }

        // Transfer NFT back
        nft.transferFrom(address(this), msg.sender, tokenId);

        // Delete stake info
        delete stakes[tokenId];

        emit Unstaked(msg.sender, tokenId, rewardAmount, feeAmount);
    }

    // Admin functions
    function setRewardRatePerDay(uint256 newRate) external onlyOwner {
        rewardRatePerDay = newRate;
        emit RewardRateUpdated(newRate);
    }

    function setFees(uint256 _stakingFeePercent, uint256 _unstakingFeePercent) external onlyOwner {
        stakingFeePercent = _stakingFeePercent;
        unstakingFeePercent = _unstakingFeePercent;
        emit FeesUpdated(_stakingFeePercent, _unstakingFeePercent);
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }
}