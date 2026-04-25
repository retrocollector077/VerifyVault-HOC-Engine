// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    // nftAddress => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    event Listed(address indexed nft, uint256 indexed tokenId, address seller, uint256 price);
    event Bought(address indexed nft, uint256 indexed tokenId, address buyer, uint256 price);
    event Canceled(address indexed nft, uint256 indexed tokenId);

    function listItem(address nft, uint256 tokenId, uint256 price) external {
        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);
        listings[nft][tokenId] = Listing(msg.sender, price, true);
        emit Listed(nft, tokenId, msg.sender, price);
    }

    function buyItem(address nft, uint256 tokenId) external payable nonReentrant {
        Listing storage lst = listings[nft][tokenId];
        require(lst.active, "Not listed");
        require(msg.value >= lst.price, "Insufficient funds");
        IERC721(nft).transferFrom(address(this), msg.sender, tokenId);
        payable(lst.seller).transfer(msg.value);
        lst.active = false;
        emit Bought(nft, tokenId, msg.sender, lst.price);
    }

    function cancelListing(address nft, uint256 tokenId) external {
        Listing storage lst = listings[nft][tokenId];
        require(lst.active, "Not active");
        require(lst.seller == msg.sender, "Not seller");
        IERC721(nft).transferFrom(address(this), msg.sender, tokenId);
        lst.active = false;
        emit Canceled(nft, tokenId);
    }
}