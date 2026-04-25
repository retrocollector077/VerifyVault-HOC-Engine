// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.29; 

 "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

 "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 

"@openzeppelin/contracts/access/Ownable.sol"; "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol" 

contract BTBBZFractionalVault is Ownable { 

    IERC20 public immutable btbbz; 

    IERC721 public immutable nftCollection; 

    uint256 public constant requiredBTBBZPerNFT = 100 * 10 ** 18; 

    mapping(uint256 => address) public vaultOwners; 

    mapping(uint256 => bool) public isVaulted; 

 

    constructor(address _btbbz, address _nftCollection) { 

        btbbz = IERC20(_btbbz); 

        nftCollection = IERC721(_nftCollection); 

    } 

    function depositNFT(uint256 tokenId) external { 

        require(nftCollection.ownerOf(tokenId) == msg.sender, "Not NFT owner"); 

        nftCollection.transferFrom(msg.sender, address(this), tokenId); 

        require(btbbz.transfer(msg.sender, requiredBTBBZPerNFT), "BTBBZ transfer failed"); 

        vaultOwners[tokenId] = msg.sender; 

        isVaulted[tokenId] = true; 

    } 

 

    function redeemNFT(uint256 tokenId) external { 

        require(isVaulted[tokenId], "NFT not vaulted"); 

        require(btbbz.transferFrom(msg.sender, address(this), requiredBTBBZPerNFT), "BTBBZ required"); 

        nftCollection.transferFrom(address(this), msg.sender, tokenId); 

        isVaulted[tokenId] = false; 

    } 

 

    function vaultStatus(uint256 tokenId) external view returns (bool) { 

        return isVaulted[tokenId]; 

    } 

 

    function withdrawBTBBZ(uint256 amount) external onlyOwner { 

        require(btbbz.transfer(msg.sender, amount), "Withdraw failed"); 

    } 

} 

""" 

