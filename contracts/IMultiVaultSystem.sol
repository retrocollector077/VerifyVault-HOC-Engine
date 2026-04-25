// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title IMultiVaultSystem
 * @notice Interface for vault system with seize and lockNFT functions.
 */
interface IMultiVaultSystem {
    function seize(address user, address asset, uint256 amount, address liquidator) external;
    function lockNFT(address collection, uint256 tokenId) external;
}

/**
 * @title MultiVaultSystemWithFees
 * @notice Implementation of IMultiVaultSystem with secure fee routing to a fixed payout address.
 */
contract MultiVaultSystemWithFees is IMultiVaultSystem, Ownable, ReentrancyGuard {
    // Hardcoded payout address (replace with actual address)
    address public constant payoutAddress = 0xb71CAb9c1C2fEC09Ed84269dA6353Fb0a19CFf8d;

    // Fee basis points (max 10000 = 100%)
    uint16 public feeBps;

    // Events
    event Seize(address indexed user, address indexed asset, uint256 amount, address indexed liquidator);
    event LockNFT(address indexed collection, uint256 tokenId);
    event FeeUpdated(uint16 newFeeBps);
    event FeesWithdrawn(address indexed to, uint256 amount);

    /**
     * @dev Constructor sets initial fee basis points.
     * @param initialFeeBps Initial fee basis points.
     */
    constructor(uint16 initialFeeBps) {
        require(initialFeeBps <= 10000, "Max fee 100%");
        feeBps = initialFeeBps;
    }

    /**
     * @dev Admin function to update fee basis points.
     * @param _newFeeBps New fee basis points.
     */
    function setFeeBps(uint16 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 10000, "Max fee 100%");
        feeBps = _newFeeBps;
        emit FeeUpdated(_newFeeBps);
    }

    /**
     * @notice Seize assets from a user during liquidation.
     * @param user The address of the user.
     * @param asset The address of the asset.
     * @param amount The amount to seize.
     * @param liquidator The address executing the liquidation.
     */
    function seize(address user, address asset, uint256 amount, address liquidator) external override nonReentrant {
        // Security checks or access control can be added here
        require(user != address(0), "Invalid user");
        require(asset != address(0), "Invalid asset");
        require(liquidator != address(0), "Invalid liquidator");

        // Transfer asset from user to liquidator (assuming ERC20)
        require(IERC20(asset).transferFrom(user, liquidator, amount), "Transfer failed");

        emit Seize(user, asset, amount, liquidator);
    }

    /**
     * @notice Lock an NFT into the vault system.
     * @param collection The NFT collection address.
     * @param tokenId The token ID.
     */
    function lockNFT(address collection, uint256 tokenId) external override nonReentrant {
        require(collection != address(0), "Invalid collection");
        IERC721(collection).transferFrom(msg.sender, address(this), tokenId);
        emit LockNFT(collection, tokenId);
    }

    /**
     * @notice Route collected ETH fees to the payout address.
     * @dev The caller should send ETH when calling this function.
     */
    function routeFees() external payable nonReentrant {
        require(msg.value > 0, "No ETH sent");
        uint256 feeAmount = (msg.value * feeBps) / 10000;

        // Transfer fee to payout address
        (bool success, ) = payoutAddress.call{value: feeAmount}("");
        require(success, "Fee transfer failed");

        // Remaining ETH stays in pool for owner withdrawal
        // Optionally, track total accumulated ETH fees
    }

    /**
     * @notice Owner can withdraw ETH from the contract.
     * @param amount The amount to withdraw.
     */
    function withdrawETH(uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = payoutAddress.call{value: amount}("");
        require(success, "Withdrawal failed");
        emit FeesWithdrawn(payoutAddress, amount);
    }

    /**
     * @dev Fallback to accept ETH.
     */
    receive() external payable {}
}