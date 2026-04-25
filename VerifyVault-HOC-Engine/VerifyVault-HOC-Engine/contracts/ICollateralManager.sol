
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;interface ICollateralManager {    function userDebt(address user, address asset) external view returns (uint256);    function isHealthy(address user) external view returns (bool);    function collateralAmount(address user, address asset) external view returns (uint256);}

