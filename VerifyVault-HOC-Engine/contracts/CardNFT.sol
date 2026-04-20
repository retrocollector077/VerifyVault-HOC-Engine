// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface AggregatorV3Interface {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns (uint8);
}

contract CardNFT is ERC721, ERC2981, Ownable, ReentrancyGuard, Initializable {
    error AlreadySold();
    error WrongETH();
    error PaymentFailed();

    IERC20 public immutable wbtc;
    AggregatorV3Interface public immutable btcUsd;
    AggregatorV3Interface public immutable ethUsd;
    address public immutable payout;

    uint256 public immutable btcPriceSats;
    string public cardMetadata;
    bool public sold;

    // Initialize function for upgradeable pattern
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory metadata_,
        uint256 btcSats_,
        address wbtc_,
        address btcUsd_,
        address ethUsd_,
        address payout_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __Ownable_init();

        wbtc = IERC20(wbtc_);
        btcUsd = AggregatorV3Interface(btcUsd_);
        ethUsd = AggregatorV3Interface(ethUsd_);
        payout = payout_;
        btcPriceSats = btcSats_;
        cardMetadata = metadata_;

        _setDefaultRoyalty(payout_, 500); // 5%
    }

    function _priceInWei() public view returns (uint256) {
        (, int256 btcPx,,,) = btcUsd.latestRoundData();
        (, int256 ethPx,,,) = ethUsd.latestRoundData();
        require(btcPx > 0 && ethPx > 0, "bad price");

        uint8 bDec = btcUsd.decimals();
        uint8 eDec = ethUsd.decimals();

        uint256 btcUsdNorm = uint256(btcPx) * (10 ** (18 - bDec));
        uint256 ethUsdNorm = uint256(ethPx) * (10 ** (18 - eDec));

        uint256 usdVal = (btcPriceSats * btcUsdNorm) / 1e8;
        return (usdVal * 1e18) / ethUsdNorm;
    }

    function buyWithETH() external payable nonReentrant {
        if (sold) revert AlreadySold();
        uint256 needWei = _priceInWei();
        if (msg.value < needWei) revert WrongETH();
        sold = true;
        _safeMint(msg.sender, 1);
        (bool ok,) = payout.call{value: msg.value}("");
        if (!ok) revert PaymentFailed();
    }

    function buyWithWBTC() external nonReentrant {
        if (sold) revert AlreadySold();
        sold = true;
        _safeMint(msg.sender, 1);
        require(wbtc.transferFrom(msg.sender, payout, btcPriceSats), "wbtc fail");
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return cardMetadata;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}