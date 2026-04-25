// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CollateralManager is OwnableUpgradeable {
    struct Config {
        bool supported;
        uint256 ltv;
        uint256 liquidationLTV;
    }

    mapping(address => Config) public collateralConfig;
    address public primary;

    event CollateralSupported(address indexed asset, uint256 ltv, uint256 liquidationLTV);
    event CollateralSupportRemoved(address indexed asset);
    event PrimaryAssetChanged(address indexed newPrimary);

    function initialize(address _primary) public initializer {
        __Ownable_init();
        primary = _primary;
    }

    function addCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationLTV
    ) external onlyOwner {
        require(asset != address(0), "Invalid asset");
        require(ltv > 0 && ltv <= 1e18, "Invalid LTV");
        require(liquidationLTV > 0 && liquidationLTV <= 1e18, "Invalid liquidationLTV");
        collateralConfig[asset] = Config({supported: true, ltv: ltv, liquidationLTV: liquidationLTV});
        emit CollateralSupported(asset, ltv, liquidationLTV);
    }

    function removeCollateral(address asset) external onlyOwner {
        delete collateralConfig[asset];
        emit CollateralSupportRemoved(asset);
    }

    function isCollateralSupported(address asset) external view returns (bool) {
        return collateralConfig[asset].supported;
    }

    function getPrimaryAsset() external view returns (address) {
        return primary;
    }

    function setPrimaryAsset(address newPrimary) external onlyOwner {
        require(newPrimary != address(0), "Invalid address");
        primary = newPrimary;
        emit PrimaryAssetChanged(newPrimary);
    }
}