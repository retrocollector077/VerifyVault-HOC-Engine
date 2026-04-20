
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
}

interface IERC721 {
    function transferFrom(address, address, uint256) external;
}

/**
 * @title AuctionHouse
 * @notice Liquidates vault collateral through competitive bidding with fees and safeguards.
 */
contract AuctionHouse {
    struct Auction {
        address seller;               // Owner of the collateral (vault owner)
        address vault;                // Vault address (NFT collection)
        uint256 tokenId;              // NFT token ID
        uint256 highestBid;           // Current highest bid
        address highestBidder;        // Highest bidder address
        uint256 startTime;            // Auction start timestamp
        uint256 endTime;              // Auction end timestamp
        bool active;                  // Is auction active?
        bool settled;                 // Has auction been settled?
    }

    // Configurable parameters
    uint256 public minBidIncrementBps = 500; // 5%
    uint256 public auctionDuration = 3 days;
    uint256 public feeBps = 200;             // 2% fee on final bid
    address public owner;

    // Your wallet address for fee collection (hardcoded)
    address public constant feeRecipient = 0x8B8143864297858b81d02b76dF2a5C1824eA01E8;

    uint256 public auctionCount;
    mapping(uint256 => Auction) public auctions;
    mapping(address => uint256) public pendingReturns; // Refunds for outbid bidders

    // Events
    event AuctionStarted(uint256 indexed id, address indexed vault, uint256 tokenId, address indexed seller, uint256 endTime);
    event NewBid(uint256 indexed id, address indexed bidder, uint256 amount);
    event BidWithdrawn(address indexed bidder, uint256 amount);
    event AuctionExtended(uint256 indexed id, uint256 newEndTime);
    event AuctionClosed(uint256 indexed id, address indexed winner, uint256 finalPrice);
    event FeesUpdated(uint256 newFeeBps);
    event BidIncrementUpdated(uint256 newMinBidIncrementBps);
    event AuctionDurationUpdated(uint256 newDuration);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyActiveAuction(uint256 id) {
        require(auctions[id].active, "Auction not active");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Admin functions
    function setFeeBps(uint256 _feeBps) external onlyOwner {
        require(_feeBps <= 1000, "Fee too high"); // Max 10%
        feeBps = _feeBps;
        emit FeesUpdated(_feeBps);
    }

    function setBidIncrementBps(uint256 _minBidIncrementBps) external onlyOwner {
        require(_minBidIncrementBps <= 10000, "Too high");
        minBidIncrementBps = _minBidIncrementBps;
        emit BidIncrementUpdated(_minBidIncrementBps);
    }

    function setAuctionDuration(uint256 _duration) external onlyOwner {
        require(_duration >= 1 hours && _duration <= 7 days, "Invalid duration");
        auctionDuration = _duration;
        emit AuctionDurationUpdated(_duration);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice Start an auction for an NFT collateral.
     * @param vault Address of the NFT collection (ERC721).
     * @param tokenId Token ID.
     */
    function startAuction(address vault, uint256 tokenId) external onlyOwner returns (uint256) {
        uint256 endTime = block.timestamp + auctionDuration;
        auctionCount++;
        auctions[auctionCount] = Auction({
            seller: msg.sender,
            vault: vault,
            tokenId: tokenId,
            highestBid: 0,
            highestBidder: address(0),
            startTime: block.timestamp,
            endTime: endTime,
            active: true,
            settled: false
        });
        emit AuctionStarted(auctionCount, vault, tokenId, msg.sender, endTime);
        return auctionCount;
    }

    /**
     * @notice Place a bid on an active auction.
     * @param id Auction ID.
     */
    function bid(uint256 id) external payable onlyActiveAuction(id) {
        Auction storage a = auctions[id];
        require(block.timestamp < a.endTime, "Auction ended");
        uint256 bidAmount = msg.value;
        require(bidAmount > a.highestBid, "Bid too low");

        uint256 minRequiredBid = a.highestBid + ((a.highestBid * minBidIncrementBps) / 10000);
        require(bidAmount >= minRequiredBid, "Bid not high enough");

        // Refund previous highest bidder
        if (a.highestBidder != address(0)) {
            pendingReturns[a.highestBidder] += a.highestBid;
        }

        // Update highest bid
        a.highestBid = bidAmount;
        a.highestBidder = msg.sender;

        emit NewBid(id, msg.sender, bidAmount);

        // Extend auction if close to end
        uint256 timeLeft = a.endTime - block.timestamp;
        if (timeLeft < 1 hours) {
            a.endTime += 15 minutes;
            emit AuctionExtended(id, a.endTime);
        }
    }

    /**
     * @notice Withdraw bid funds if outbid.
     */
    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");
        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit BidWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Close auction after end time, transfer NFT, and distribute proceeds.
     * @param id Auction ID.
     */
    function closeAuction(uint256 id) external onlyOwner onlyActiveAuction(id) {
        Auction storage a = auctions[id];
        require(block.timestamp >= a.endTime, "Auction not ended");
        a.active = false;

        address winner = a.highestBidder;
        uint256 finalPrice = a.highestBid;

        require(winner != address(0), "No bids placed");

        // Transfer NFT from vault to winner
        IERC721(a.vault).transferFrom(address(this), winner, a.tokenId);

        // Distribute funds
        uint256 feeAmount = (finalPrice * feeBps) / 10000;
        uint256 sellerProceeds = finalPrice - feeAmount;

        // Transfer fee to feeRecipient
        payable(feeRecipient).transfer(feeAmount);
        // Transfer proceeds to seller (original owner)
        payable(a.seller).transfer(sellerProceeds);

        emit AuctionClosed(id, winner, finalPrice);
    }

    // Fallback functions to accept ETH
    receive() external payable {}
    fallback() external payable {}
}