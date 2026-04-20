// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.29; 

 

/** 

 * @title BTBBZFractionalVault 

 * @dev Converts ERC721 assets into fractional ERC20 shares (wBTBBZ). 

 * Enables redemption, valuation updates, and vault Proof-of-Reserve linking. 

 * Integrated with VerifyVault Mint721 NFTs and WrappedBTBBZ ERC20 token. 

 */ 

 

import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol"; 

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol"; 

import "@openzeppelin/contracts/access/Ownable.sol"; 

import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol"; 

import "@openzeppelin/contracts/proxy/utils/Initializable.sol"; 

 

interface IOracleHub { 

    function getAssetValue(address asset, uint256 tokenId) external view returns (uint256); 

} 

 

contract BTBBZFractionalVault is 

    ERC20Burnable, 

    ERC20Pausable, 

    Ownable, 

    ReentrancyGuard, 

    Initializable, 

    UUPSUpgradeable 

{ 

    // ============================================================= 

    //                           STATE 

    // ============================================================= 

 

    IERC721 public immutable nftContract; 

    IOracleHub public oracleHub; 

    address public proofOfReserveFeed; 

    mapping(uint256 => address) public depositedBy; 

    mapping(uint256 => uint256) public shareValue; 

 

    event NFTDeposited(address indexed depositor, uint256 indexed tokenId, uint256 sharesMinted); 

    event NFTRedeemed(address indexed redeemer, uint256 indexed tokenId, uint256 sharesBurned); 

    event OracleUpdated(address indexed oracle); 

    event ProofFeedLinked(string feedId); 

 

    /// @custom:oz-upgrades-unsafe-allow constructor 

    constructor(address _nft) ERC20("BTBBZ Vault Share", "wBTBBZ") { 

        nftContract = IERC721(_nft); 

    } 

 

    function initialize(address _oracleHub, address _admin) public initializer { 

        oracleHub = IOracleHub(_oracleHub); 

        _transferOwnership(_admin); 

    } 

 

    // ============================================================= 

    //                     INTERNAL UUPS AUTH 

    // ============================================================= 

 

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {} 

 

    // ============================================================= 

    //                         DEPOSIT LOGIC 

    // ============================================================= 

 

    function depositNFT(address from, uint256 tokenId) 

        external 

        nonReentrant 

        whenNotPaused 

        returns (uint256 shares) 

    { 

        require(msg.sender == from || nftContract.getApproved(tokenId) == msg.sender, "Not approved"); 

        nftContract.transferFrom(from, address(this), tokenId); 

 

        // get valuation from OracleHub 

        uint256 value = oracleHub.getAssetValue(address(nftContract), tokenId); 

        require(value > 0, "Invalid oracle value"); 

 

        // 1 share per unit (e.g., 1 BTBBZ = $1 value equivalent) 

        shares = value; 

        _mint(from, shares); 

 

        depositedBy[tokenId] = from; 

        shareValue[tokenId] = value; 

 

        emit NFTDeposited(from, tokenId, shares); 

    } 

 

    // ============================================================= 

    //                         REDEMPTION 

    // ============================================================= 

 

    function redeemShares(uint256 tokenId) external nonReentrant whenNotPaused { 

        address depositor = depositedBy[tokenId]; 

        require(depositor != address(0), "Token not deposited"); 

        require(balanceOf(msg.sender) >= shareValue[tokenId], "Insufficient shares"); 

 

        uint256 burnAmt = shareValue[tokenId]; 

        _burn(msg.sender, burnAmt); 

 

        nftContract.transferFrom(address(this), msg.sender, tokenId); 

 

        delete depositedBy[tokenId]; 

        delete shareValue[tokenId]; 

 

        emit NFTRedeemed(msg.sender, tokenId, burnAmt); 

    } 

 

    // ============================================================= 

    //                        ADMIN CONTROLS 

    // ============================================================= 

 

    function pause() external onlyOwner { 

        _pause(); 

    } 

 

    function unpause() external onlyOwner { 

        _unpause(); 

    } 

 

    function updateOracleHub(address newOracle) external onlyOwner { 

        oracleHub = IOracleHub(newOracle); 

        emit OracleUpdated(newOracle); 

    } 

 

    function linkProofFeed(address feed) external onlyOwner { 

        proofOfReserveFeed = feed; 

        emit ProofFeedLinked("Chainlink BTBBZ Feed Linked"); 

    } 

 

    // ============================================================= 

    //                        VIEW FUNCTIONS 

    // ============================================================= 

 

    function getVaultStatus(uint256 tokenId) 

        external 

        view 

        returns ( 

            address depositor, 

            uint256 value, 

            uint256 shares 

        ) 

    { 

        return (depositedBy[tokenId], shareValue[tokenId], balanceOf(depositedBy[tokenId])); 

    } 

} 

npx hardhat run scripts/deploy_BTBBZFractionalVault.js --network linea 

["0x...Mint721_Collection_Address"] 

["0x...OracleHub_Address", "0x...Admin_Owner_Address"]