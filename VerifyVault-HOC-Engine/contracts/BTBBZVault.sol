// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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

/**
 * @title BTBBZVault
 * @notice Fractionalization vault for ERC721 assets.
 * Converts NFTs → BTBBZ shares based on oracle valuation.
 * 
 * Integrates with:
 * - Minting of NFTs
 * - OracleHub for valuation
 * - SyntheticUSD for borrowing
 * - MultiVaultSystem for collateral
 * - LiquidationEngine for liquidations
 * - RouterLinea for cross-chain arbitrage
 */
contract BTBBZVault is Initializable {
    // Events
    event NFTDeposited(address indexed user, address indexed collection, uint256 tokenId, uint256 sharesMinted);
    event SharesRedeemed(address indexed user, uint256 shares, uint256 tokenIdReleased);
    event OwnershipTransferred(address oldOwner, address newOwner);

    // Owner management
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // References
    IOracleHubB public oracle;
    IERC20B public btbbzToken;

    // NFT Record
    struct NFTRecord {
        address owner;
        address collection;
        uint256 tokenId;
        uint256 shares; // minted shares
        bool exists;
    }

    // Storage
    uint256 public nextFractionalId;
    mapping(uint256 => NFTRecord) public records; // fractionalId => NFT
    mapping(address => mapping(uint256 => uint256)) public fractionalIdOf; // NFT => fractionalId

    // Initialization
    function initialize(address oracle_, address btbbzToken_) public initializer {
        owner = msg.sender;
        oracle = IOracleHubB(oracle_);
        btbbzToken = IERC20B(btbbzToken_);
        nextFractionalId = 1;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // Ownership transfer
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Deposit NFT and mint shares
    function depositNFT(address collection, uint256 tokenId) external returns (uint256 sharesMinted) {
        // Transfer NFT to vault
        IERC721B(collection).transferFrom(msg.sender, address(this), tokenId);

        // Get valuation
        uint256 valuationUSD = oracle.getNFTValue(collection, tokenId);
        require(valuationUSD > 0, "Oracle returned zero");

        // Mint shares (1 USD = 1 share, 18 decimals)
        sharesMinted = valuationUSD;

        // Mint shares to user
        btbbzToken.mint(msg.sender, sharesMinted);

        // Record fractionalization
        uint256 fid = nextFractionalId++;
        records[fid] = NFTRecord({
            owner: msg.sender,
            collection: collection,
            tokenId: tokenId,
            shares: sharesMinted,
            exists: true
        });
        fractionalIdOf[collection][tokenId] = fid;

        emit NFTDeposited(msg.sender, collection, tokenId, sharesMinted);
        return sharesMinted;
    }

    // Redeem shares for NFT
    function redeemShares(uint256 shares) external returns (uint256 tokenId) {
        // Find the NFT record matching sender and shares
        bool found = false;
        for (uint256 fid = 1; fid < nextFractionalId; fid++) {
            NFTRecord storage r = records[fid];
            if (r.exists && r.owner == msg.sender && r.shares == shares) {
                // Mark record inactive
                r.exists = false;

                // Burn shares
                btbbzToken.burn(msg.sender, shares);

                // Transfer NFT back
                IERC721B(r.collection).transferFrom(address(this), msg.sender, r.tokenId);

                emit SharesRedeemed(msg.sender, shares, r.tokenId);
                return r.tokenId;
            }
        }
        revert("No matching NFT for shares");
    }

    // View functions
    function getNFTRecord(uint256 fid) external view returns (NFTRecord memory) {
        return records[fid];
    }

    function fractionalIdFor(address collection, uint256 tokenId) external view returns (uint256) {
        return fractionalIdOf[collection][tokenId];
    }
}