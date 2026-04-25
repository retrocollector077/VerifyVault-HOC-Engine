// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IInterestRateModelFL {
    function getFlashLoanPremium(uint256 volatility1e18) external view returns (uint256);
}

interface IOracleHubFL {
    function getPrice(bytes32 asset) external view returns (uint256 price, uint256 vol);
}

interface IFeeSplitTreasuryFL {
    function routeFlashLoanFee() external payable;
}

interface IFlashLoanReceiver {
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        bytes calldata params
    ) external returns (bool);
}

contract FlashLoanProviderV3 is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IInterestRateModelFL public irm;
    IOracleHubFL public oracle;
    IFeeSplitTreasuryFL public treasury;

    // Fee percentage in basis points (e.g., 100 = 1%)
    uint256 public flashLoanFeePercent;

    // Reserves for each asset
    mapping(address => uint256) public reserves;

    event FlashLoanExecuted(
        address indexed receiver,
        address indexed asset,
        uint256 amount,
        uint256 fee
    );

    // ---------------------------------------------------------
    // Initialization
    // ---------------------------------------------------------
    function initialize(
        address _irm,
        address _oracle,
        address _treasury,
        uint256 _initialFeePercent
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        irm = IInterestRateModelFL(_irm);
        oracle = IOracleHubFL(_oracle);
        treasury = IFeeSplitTreasuryFL(_treasury);
        flashLoanFeePercent = _initialFeePercent;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // Authorization for upgrade
    function _authorizeUpgrade(address impl) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ---------------------------------------------------------
    // Admin functions to set fee percentage
    // ---------------------------------------------------------
    function setFlashLoanFeePercent(uint256 newPercent) external onlyRole(ADMIN_ROLE) {
        require(newPercent <= 10000, "Fee cannot exceed 100%");
        flashLoanFeePercent = newPercent;
    }

    // ---------------------------------------------------------
    // Liquidity Management
    // ---------------------------------------------------------
    function deposit(address asset, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        reserves[asset] += amount;
    }

    // ---------------------------------------------------------
    // Flash Loan
    // ---------------------------------------------------------
    function flashLoan(
        address receiver,
        address asset,
        uint256 amount,
        bytes calldata params
    ) external nonReentrant {
        uint256 available = reserves[asset];
        require(amount > 0 && amount <= available, "Insufficient liquidity");

        // Calculate premium based on volatility
        ( , uint256 vol ) = oracle.getPrice("RC77"); // replace with correct asset key
        uint256 premium = irm.getFlashLoanPremium(vol);

        // Calculate fee as percentage of amount
        uint256 fee = (amount * flashLoanFeePercent) / 10000;

        // Deduct from reserves
        reserves[asset] -= amount;

        // Transfer the flash loan amount
        IERC20(asset).transfer(receiver, amount);

        // Execute callback
        require(
            IFlashLoanReceiver(receiver).executeOperation(asset, amount, fee, params),
            "Callback failed"
        );

        // Expect repayment of amount + fee
        IERC20(asset).transferFrom(receiver, address(this), amount + fee);
        reserves[asset] += amount + fee;

        // Route fee to treasury
        treasury.routeFlashLoanFee{value: fee}();

        emit FlashLoanExecuted(receiver, asset, amount, fee);
    }

    // Optional: Emergency functions or additional features
}