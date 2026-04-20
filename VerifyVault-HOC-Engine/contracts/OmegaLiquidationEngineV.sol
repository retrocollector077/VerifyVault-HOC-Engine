// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IOracleHub} from "../interfaces/IOracleHub.sol";
import {ICollateralManager} from "../interfaces/ICollateralManager.sol";
import {IInterestRateModel} from "../interfaces/IInterestRateModel.sol";
import {IMultiVaultSystem} from "../interfaces/IMultiVaultSystem.sol";
import {IVerifyUSD} from "../interfaces/IVerifyUSD.sol";

import {LiquidationMath} from "../libraries/LiquidationMath.sol";

contract OmegaLiquidationEngineEdge is
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using LiquidationMath for uint256;

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // External dependencies
    IOracleHub public oracle;
    ICollateralManager public collateralManager;
    IInterestRateModel public interestModel;
    IMultiVaultSystem public vaultSystem;
    IVerifyUSD public verifyUSD;

    // Configurable parameters
    uint256 public liquidationPenalty;    // basis points, e.g., 850 = 8.5%
    uint256 public mevGuardDelay;         // block delay for MEV protection
    uint256 public minLiquidationAmount;  // minimum debt to trigger liquidation

    // Treasuries (configure as needed)
    address public treasuryPrimary;
    address public treasurySecondary1;
    address public treasurySecondary2;
    address public treasurySecondary3;
    address public treasurySecondary4;

    // State
    mapping(address => uint256) public lastExecutionBlock;
    bool public paused;

    // Events
    event Liquidation(
        address indexed user,
        address indexed collateralAsset,
        uint256 debtRepaid,
        uint256 collateralSeized,
        address liquidator
    );

    event TreasuryDistribution(
        uint256 primaryAmount,
        uint256 secondary1Amount,
        uint256 secondary2Amount,
        uint256 secondary3Amount,
        uint256 secondary4Amount
    );

    event ParametersUpdated(uint256 penalty, uint256 mevDelay, uint256 minDebt);
    event Paused(address account);
    event Unpaused(address account);
    event Upgrade(address newImplementation);

    // Initializer
    function initialize(
        address _oracle,
        address _collateralManager,
        address _interestModel,
        address _vaultSystem,
        address _verifyUSD,
        address[] calldata treasuries
    ) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        require(_oracle != address(0), "Invalid oracle");
        require(_collateralManager != address(0), "Invalid collateral");
        require(_interestModel != address(0), "Invalid interest");
        require(_vaultSystem != address(0), "Invalid vault");
        require(_verifyUSD != address(0), "Invalid verifyUSD");
        require(treasuries.length == 5, "Treasuries missing");

        oracle = IOracleHub(_oracle);
        collateralManager = ICollateralManager(_collateralManager);
        interestModel = IInterestRateModel(_interestModel);
        vaultSystem = IMultiVaultSystem(_vaultSystem);
        verifyUSD = IVerifyUSD(_verifyUSD);

        treasuryPrimary = treasuries[0];
        treasurySecondary1 = treasuries[1];
        treasurySecondary2 = treasuries[2];
        treasurySecondary3 = treasuries[3];
        treasurySecondary4 = treasuries[4];

        // Default parameters
        liquidationPenalty = 850; // 8.5%
        mevGuardDelay = 2; // blocks
        minLiquidationAmount = 1e18; // minimum debt (e.g., 1 USD in token units)

        emit ParametersUpdated(liquidationPenalty, mevGuardDelay, minLiquidationAmount);
    }

    // --- Modifiers ---
    modifier mevProtection(address executor) {
        require(
            block.number > lastExecutionBlock[executor] + mevGuardDelay,
            "MEV protection active"
        );
        lastExecutionBlock[executor] = block.number;
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract paused");
        _;
    }

    // --- Administrative functions ---
    function updateParameters(
        uint256 _penalty,
        uint256 _mevDelay,
        uint256 _minDebt
    ) external onlyRole(ADMIN_ROLE) {
        require(_penalty <= 2000, "Penalty too high");
        require(_mevDelay <= 10, "MEV delay too high");
        liquidationPenalty = _penalty;
        mevGuardDelay = _mevDelay;
        minLiquidationAmount = _minDebt;
        emit ParametersUpdated(_penalty, _mevDelay, _minDebt);
    }

    function setTreasuries(address[] calldata treasuries) external onlyRole(ADMIN_ROLE) {
        require(treasuries.length == 5, "Invalid treasuries");
        treasuryPrimary = treasuries[0];
        treasurySecondary1 = treasuries[1];
        treasurySecondary2 = treasuries[2];
        treasurySecondary3 = treasuries[3];
        treasurySecondary4 = treasuries[4];
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Core liquidation ---
    function liquidate(
        address user,
        address debtAsset,
        address collateralAsset
    ) external notPaused mevProtection(msg.sender) {
        uint256 userDebt = collateralManager.userDebt(user, debtAsset);
        require(userDebt >= minLiquidationAmount, "Debt below min");
        require(userDebt > 0, "No debt");

        // Verify health
        require(!collateralManager.isHealthy(user), "Position healthy");

        // Get oracle prices
        uint256 priceDebt = oracle.getPrice(bytes32ToBytes32(debtAsset));
        uint256 priceColl = oracle.getPrice(bytes32ToBytes32(collateralAsset));
        require(priceDebt > 0 && priceColl > 0, "Invalid oracle data");

        // Calculate amount to repay
        uint256 repayAmount = userDebt;

        // Transfer debt tokens from liquidator
        require(
            IERC20(debtAsset).transferFrom(msg.sender, address(this), repayAmount),
            "Debt transfer failed"
        );

        // Calculate collateral to seize
        uint256 collateralUSDValue = repayAmount * priceDebt;
        uint256 bonus = collateralUSDValue.applyPenalty(liquidationPenalty);
        uint256 collateralToSeize = bonus / priceColl;

        // Seize collateral
        vaultSystem.seize(user, collateralAsset, collateralToSeize, msg.sender);

        // Burn debt tokens
        require(verifyUSD.burn(address(this), repayAmount), "Burn failed");

        emit Liquidation(
            user,
            collateralAsset,
            repayAmount,
            collateralToSeize,
            msg.sender
        );

        _distributeTreasury(repayAmount);
    }

    // Internal treasury distribution
    function _distributeTreasury(uint256 amount) internal {
        uint256 share = amount / 5;

        require(IERC20(address(verifyUSD)).transfer(treasuryPrimary, share), "Primary transfer failed");
        require(IERC20(address(verifyUSD)).transfer(treasurySecondary1, share), "Secondary1 transfer failed");
        require(IERC20(address(verifyUSD)).transfer(treasurySecondary2, share), "Secondary2 transfer failed");
        require(IERC20(address(verifyUSD)).transfer(treasurySecondary3, share), "Secondary3 transfer failed");
        require(IERC20(address(verifyUSD)).transfer(treasurySecondary4, share), "Secondary4 transfer failed");

        emit TreasuryDistribution(share, share, share, share, share);
    }

    // --- Utility ---
    function bytes32ToBytes32(address a) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }

    // --- Upgradeable ---
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}