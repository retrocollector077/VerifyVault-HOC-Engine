
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/**
 * @title BTBBZVault
 * @notice Fractionalization vault for ERC721 assets with fee mechanisms and liquidity considerations.
 *         Converts NFTs → BTBBZ shares based on oracle valuation.
 *         Supports configurable fees and fee collection.
 */

interface IERC721B {
    function transferFrom(address src, address dst, uint256 tokenId) external;
}

interface IERC20B {
    function transfer(address dst, uint256 amount) external returns (bool);
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

interface IOracleHubB {
    function getNFTValue(address collection, uint256 tokenId) external view returns (uint256);
}

contract BTBBZVault {
    // ---------------------------------------------------------
    // EVENTS
    // ---------------------------------------------------------
    event NFTDeposited(address indexed user, address indexed collection, uint256 tokenId, uint256 sharesMinted);
    event SharesRedeemed(address indexed user, uint256 shares, uint256 tokenIdReleased);
    event OwnershipTransferred(address oldOwner, address newOwner);
    event FeesUpdated(uint256 depositFeeBps, uint256 redemptionFeeBps);
    event FeeCollectorUpdated(address oldFeeCollector, address newFeeCollector);

    // ---------------------------------------------------------
    // OWNER & ADMIN
    // ---------------------------------------------------------
    address public owner;
    address public feeCollector; // Address to collect fees

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address oracle_, address btbbzToken_, address feeCollector_) {
        owner = msg.sender;
        oracle = IOracleHubB(oracle_);
        btbbzToken = IERC20B(btbbzToken_);
        feeCollector = feeCollector_;
        emit OwnershipTransferred(address(0), msg.sender);
        emit FeeCollectorUpdated(address(0), feeCollector_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function updateFeeCollector(address newFeeCollector) external onlyOwner {
        require(newFeeCollector != address(0), "Zero address");
        emit FeeCollectorUpdated(feeCollector, newFeeCollector);
        feeCollector = newFeeCollector;
    }

    // ---------------------------------------------------------
    // CONFIGURABLE FEES
    // ---------------------------------------------------------
    // Fees are in basis points (bps): 100 bps = 1%
    uint256 public depositFeeBps = 200;    // Default 2%
    uint256 public redemptionFeeBps = 200; // Default 2%

    uint256 public constant MAX_FEE_BPS = 1000; // Max 10% fee

    function setFees(uint256 _depositFeeBps, uint256 _redemptionFeeBps) external onlyOwner {
        require(_depositFeeBps <= MAX_FEE_BPS, "Deposit fee too high");
        require(_redemptionFeeBps <= MAX_FEE_BPS, "Redemption fee too high");
        depositFeeBps = _depositFeeBps;
        redemptionFeeBps = _redemptionFeeBps;
        emit FeesUpdated(_depositFeeBps, _redemptionFeeBps);
    }

    // ---------------------------------------------------------
    // STATE VARIABLES
    // ---------------------------------------------------------
    IERC20B public btbbzToken;        // ERC20 token representing shares
    IOracleHubB public oracle;         // NFT valuation oracle

    struct NFTRecord {
        address owner;
        address collection;
        uint256 tokenId;
        uint256 shares; // minted shares
        bool exists;
    }

    // Mapping: fractionalId -> NFTRecord
    mapping(uint256 => NFTRecord) public records;
    // Mapping: collection + tokenId -> fractionalId
    mapping(address => mapping(uint256 => uint256)) public fractionalIdOf;
    uint256 public nextFractionalId = 1;

    // ---------------------------------------------------------
    // MAIN FUNCTIONS
    // ---------------------------------------------------------

    /**
     * @notice Deposit NFT and mint BTBBZ shares based on oracle valuation, minus fees.
     * @param collection Address of the NFT collection.
     * @param tokenId Token ID of the NFT.
     */
    function depositNFT(address collection, uint256 tokenId) external returns (uint256 sharesMinted) {
        // Transfer NFT to vault
        IERC721B(collection).transferFrom(msg.sender, address(this), tokenId);

        // Get valuation in USD (18 decimals)
        uint256 valuationUSD = oracle.getNFTValue(collection, tokenId);
        require(valuationUSD > 0, "Oracle returned zero");

        // Calculate fee
        uint256 fee = (valuationUSD * depositFeeBps) / 10000;
        uint256 netValuation = valuationUSD - fee;

        // Mint shares to user
        btbbzToken.mint(msg.sender, netValuation);
        // Transfer fee to feeCollector
        if (fee > 0) {
            btbbzToken.mint(feeCollector, fee);
        }

        // Record fractionalization
        uint256 fid = nextFractionalId++;
        records[fid] = NFTRecord({
            owner: msg.sender,
            collection: collection,
            tokenId: tokenId,
            shares: netValuation,
            exists: true
        });
        fractionalIdOf[collection][tokenId] = fid;

        emit NFTDeposited(msg.sender, collection, tokenId, netValuation);
        return netValuation;
    }

    /**
     * @notice Redeem shares for the original NFT. Applies fee.
     * @param shares Number of shares to redeem.
     */
    function redeemShares(uint256 shares) external returns (uint256 tokenId) {
        // Find the NFT associated with these shares
        uint256 fid = 0;
        for (uint256 i = 1; i < nextFractionalId; i++) {
            if (!records[i].exists) continue;
            if (records[i].owner == msg.sender && records[i].shares == shares) {
                fid = i;
                break;
            }
        }
        require(fid != 0, "No matching NFT");

        NFTRecord storage r = records[fid];

        // Apply redemption fee
        uint256 fee = (shares * redemptionFeeBps) / 10000;
        uint256 sharesAfterFee = shares - fee;

        // Burn user's shares
        btbbzToken.burn(msg.sender, shares);
        if (fee > 0) {
            btbbzToken.burn(msg.sender, fee); // or transfer fee to feeCollector if preferred
            // Alternatively, mint fee shares to feeCollector
            // btbbzToken.mint(feeCollector, fee);
        }

        // Mark record as no longer exists
        r.exists = false;

        // Transfer NFT back to user
        IERC721B(r.collection).transferFrom(address(this), msg.sender, r.tokenId);

        emit SharesRedeemed(msg.sender, shares, r.tokenId);
        return r.tokenId;
    }

    // ---------------------------------------------------------
    // VIEW FUNCTIONS
    // ---------------------------------------------------------
    function getNFTRecord(uint256 fid) external view returns (NFTRecord memory) {
        return records[fid];
    }

    function fractionalIdFor(address collection, uint256 tokenId) external view returns (uint256) {
        return fractionalIdOf[collection][tokenId];
    }
}