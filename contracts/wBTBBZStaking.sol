// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract wBTBBZStaking is Ownable, ReentrancyGuard {
    IERC20 public immutable wbtbbz;
    uint256 public rewardRate; // tokens per second (scaled by 1e18)
    uint256 public totalStaked;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 rewardDebt;
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint256) public pendingRewards;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRate);

    constructor(address _wbtbbz, uint256 _rewardRate) {
        wbtbbz = IERC20(_wbtbbz);
        rewardRate = _rewardRate;
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Zero stake");
        updateRewards(msg.sender);
        require(wbtbbz.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].timestamp = block.timestamp;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        require(stakes[msg.sender].amount >= amount, "Insufficient stake");
        updateRewards(msg.sender);
        stakes[msg.sender].amount -= amount;
        totalStaked -= amount;
        require(wbtbbz.transfer(msg.sender, amount), "Transfer failed");
        emit Unstaked(msg.sender, amount);
    }

    function claim() external nonReentrant {
        updateRewards(msg.sender);
        uint256 reward = pendingRewards[msg.sender];
        require(reward > 0, "No rewards");
        pendingRewards[msg.sender] = 0;
        require(wbtbbz.transfer(msg.sender, reward), "Transfer failed");
        emit RewardsClaimed(msg.sender, reward);
    }

    function updateRewards(address user) internal {
        Stake storage s = stakes[user];
        if (s.amount > 0) {
            uint256 reward = ((block.timestamp - s.timestamp) * rewardRate * s.amount) / 1e18;
            pendingRewards[user] += reward;
            s.timestamp = block.timestamp;
        }
    }

    function setRewardRate(uint256 _rate) external onlyOwner {
        rewardRate = _rate;
        emit RewardRateUpdated(_rate);
    }

    // View function to see pending rewards without claiming
    function pendingReward(address user) external view returns (uint256) {
        Stake memory s = stakes[user];
        uint256 accruedReward = ((block.timestamp - s.timestamp) * rewardRate * s.amount) / 1e18;
        return pendingRewards[user] + accruedReward;
    }
}