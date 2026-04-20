// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
}

/**
 * @title AuctionHouse
 * @notice Liquidates vault collateral through competitive bidding.
 * Designed for upgradeability, security, and production use.
 */
contract AuctionHouse is Initializable, AccessControlUpgradeable {
    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Auction {
        address user;            // Vault owner
        address vault;           // Vault address
        uint256 highestBid;      // Current highest bid (in wei)
        address highestBidder;   // Bidder address
        bool active;             // Is auction active
        uint64 startTime;        // Auction start timestamp
        uint64 endTime;          // Auction end timestamp
    }

    // Mapping auction ID to Auction
    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCount;

    // Pending refunds for bidders
    mapping(address => uint256) public pendingRefunds;

    // Events
    event AuctionStarted(uint256 indexed id, address indexed user, address indexed vault, uint64 startTime, uint64 endTime);
    event NewBid(uint256 indexed id, address indexed bidder, uint256 amount);
    event AuctionClosed(uint256 indexed id, address indexed winner, uint256 bidAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __AccessControl_init();

        // Grant default admin role to deployer
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    // Only admin can start auction
    function startAuction(address user, address vault, uint64 durationSeconds) external onlyRole(ADMIN_ROLE) returns (uint256) {
        require(user != address(0), "Invalid user");
        require(vault != address(0), "Invalid vault");
        require(durationSeconds > 0, "Duration zero");

        auctionCount++;
        uint64 startTime = uint64(block.timestamp);
        uint64 endTime = startTime + durationSeconds;

        auctions[auctionCount] = Auction(user, vault, 0, address(0), true, startTime, endTime);
        emit AuctionStarted(auctionCount, user, vault, startTime, endTime);
        return auctionCount;
    }

    // Bid function (accepts ETH)
    function bid(uint256 id) external payable {
        Auction storage a = auctions[id];
        require(a.active, "Auction not active");
        require(block.timestamp >= a.startTime && block.timestamp <= a.endTime, "Auction not ongoing");
        require(msg.value > a.highestBid, "Bid too low");

        // Refund previous highest bidder
        if (a.highestBidder != address(0)) {
            pendingRefunds[a.highestBidder] += a.highestBid;
        }

        a.highestBid = msg.value;
        a.highestBidder = msg.sender;

        emit NewBid(id, msg.sender, msg.value);
    }

    // Claim refund for outbid bidders
    function claimRefund() external {
        uint256 amount = pendingRefunds[msg.sender];
        require(amount > 0, "No funds");
        pendingRefunds[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund transfer failed");
    }

    // Close auction (only admin)
    function closeAuction(uint256 id) external onlyRole(ADMIN_ROLE) {
        Auction storage a = auctions[id];
        require(a.active, "Already closed");
        require(block.timestamp > a.endTime, "Auction not ended");
        a.active = false;

        // Transfer collateral from vault to winner (requires vault interface)
        // For demonstration, we just emit event
        emit AuctionClosed(id, a.highestBidder, a.highestBid);

        // Note: In production, integrate vault transfer logic here
    }

    // Admin can cancel auction (optional)
    function cancelAuction(uint256 id) external onlyRole(ADMIN_ROLE) {
        Auction storage a = auctions[id];
        require(a.active, "Already closed");
        a.active = false;
        // Refund highest bidder if any bid exists
        if (a.highestBid > 0 && a.highestBidder != address(0)) {
            uint256 refundAmount = a.highestBid;
            a.highestBid = 0;
            (bool success, ) = a.highestBidder.call{value: refundAmount}("");
            require(success, "Refund failed");
        }
        emit AuctionClosed(id, address(0), 0);
    }

    // Getter for auction info
    function getAuction(uint256 id) external view returns (Auction memory) {
        return auctions[id];
    }
}