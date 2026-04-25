// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IWBTBBZVault {
    function deposit(address token, uint256 amount) external returns (uint256);
    function redeem(uint256 shares) external returns (uint256);
}