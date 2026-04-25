// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CollectionNFT is ERC721Upgradeable, OwnableUpgradeable {
    uint256 public tokenCounter;

    function initialize(string memory name, string memory symbol) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init();
        tokenCounter = 0;
    }

    function mint(address to) external onlyOwner returns (uint256) {
        tokenCounter += 1;
        _safeMint(to, tokenCounter);
        return tokenCounter;
    }
}