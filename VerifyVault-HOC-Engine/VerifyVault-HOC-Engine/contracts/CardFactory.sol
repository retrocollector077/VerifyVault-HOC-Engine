// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface ICardNFT {
    function initialize(
        string memory name,
        string memory symbol,
        string memory metadata,
        uint256 btcSats,
        address wbtc,
        address btcUsd,
        address ethUsd,
        address payout
    ) external;
}

contract CardFactory is Initializable {
    address public immutable wbtc;
    address public immutable btcUsd;
    address public immutable ethUsd;
    address public immutable payout;

    event CardDeployed(address card, string name);

    function initialize(
        address wbtc_,
        address btcUsd_,
        address ethUsd_,
        address payout_
    ) public initializer {
        wbtc = wbtc_;
        btcUsd = btcUsd_;
        ethUsd = ethUsd_;
        payout = payout_;
    }

    function deployCard(
        string memory name_,
        string memory symbol_,
        string memory metadata_,
        uint256 btcSats_
    ) external returns (address) {
        // Deploy new proxy instance of CardNFT
        // Assumes you have a minimal proxy or upgradeable implementation
        // For simplicity, use OpenZeppelin Transparent Proxy pattern
        // Deployment code depends on your deployment setup
        // Here is a simplified version assuming using OpenZeppelin's Transparent Proxy

        // You should deploy a TransparentUpgradeableProxy with the implementation address
        // For example:
        // ProxyAdmin admin;
        // TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
        //     implementationAddress,
        //     adminAddress,
        //     data
        // );
        // But for inline code, you need to deploy the implementation and proxy separately.

        // For illustration, we just instantiate a new CardNFT
        // Note: In production, you'd deploy via proxy for upgradeability

        // WARNING: This simplified approach is not upgradeable without proxies
        CardNFT nft = new CardNFT();
        nft.initialize(name_, symbol_, metadata_, btcSats_, wbtc, btcUsd, ethUsd, payout);
        emit CardDeployed(address(nft), name_);
        return address(nft);
    }
}