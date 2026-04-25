
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/**
 * @title FlashLoanProvider
 * @notice Aave-style flash loan pool supporting reserve accounting, premium fees,
 * callback interface, and optimized gas patterns.
 */
interface IFlashLoanReceiver {
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        bytes calldata data
    ) external returns (bool);
}

contract FlashLoanProvider {
    // --- Events ---
    event Deposit(address indexed asset, address indexed user, uint256 amount);
    event Withdraw(address indexed asset, address indexed user, uint256 amount);
    event FlashLoanExecuted(address indexed receiver, address asset, uint256 amount, uint256 premium);
    event OwnershipTransferred(address oldOwner, address newOwner);

    // --- Owner ---
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // --- Reserve accounting ---
    struct Reserve {
        uint256 totalLiquidity;
        uint256 totalBorrows;
        bool exists;
    }

    mapping(address => Reserve) public reserves;
    uint256 public flashLoanPremium = 9; // in basis points (0.09%)

    function setFlashLoanPremium(uint256 newPremium) external onlyOwner {
        require(newPremium <= 1000, "Too high"); // max 10%
        flashLoanPremium = newPremium;
    }

    // --- Deposit / Withdraw ---
    function deposit(address asset, uint256 amount) external payable {
        require(amount > 0, "Invalid amount");
        if (!reserves[asset].exists) {
            reserves[asset].exists = true;
        }

        // Handle ETH deposit separately
        if (asset == address(0)) {
            require(msg.value == amount, "ETH amount mismatch");
        } else {
            bool success;
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, 0x23b872dd) // transferFrom
                mstore(add(ptr, 4), caller()) // sender
                mstore(add(ptr, 36), address()) // recipient
                mstore(add(ptr, 68), amount) // amount
                success := call(gas(), asset, 0, ptr, 100, 0, 0)
            }
            require(success, "Transfer failed");
        }
        reserves[asset].totalLiquidity += amount;
        emit Deposit(asset, msg.sender, amount);
    }

    function withdraw(address asset, uint256 amount) external onlyOwner {
        require(reserves[asset].exists, "No reserve");
        require(reserves[asset].totalLiquidity >= amount, "Not enough liquidity");
        reserves[asset].totalLiquidity -= amount;

        // Handle ETH withdrawal
        if (asset == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            (bool success, ) = asset.call(
                abi.encodeWithSelector(0xa9059cbb, msg.sender, amount) // transfer(address,uint256)
            );
            require(success, "Transfer failed");
        }
        emit Withdraw(asset, msg.sender, amount);
    }

    // --- Flash loan ---
    function flashLoan(
        address receiver,
        address asset,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        Reserve storage r = reserves[asset];
        require(r.exists, "Reserve not found");
        require(r.totalLiquidity >= amount, "Insufficient liquidity");
        uint256 premium = (amount * flashLoanPremium) / 10000; // basis points
        uint256 totalRepayment = amount + premium;

        // Transfer the loan
        if (asset == address(0)) {
            payable(receiver).transfer(amount);
        } else {
            (bool success, ) = asset.call(
                abi.encodeWithSelector(0xa9059cbb, receiver, amount)
            );
            require(success, "Loan transfer failed");
        }

        // Call receiver
        require(
            IFlashLoanReceiver(receiver).executeOperation(asset, amount, premium, data),
            "Callback failed"
        );

        // Repay the loan
        if (asset == address(0)) {
            require(address(this).balance >= totalRepayment, "Repayment balance low");
            (bool success, ) = receiver.call{value: totalRepayment}(
                abi.encodeWithSelector(0xa9059cbb, address(this), totalRepayment)
            );
            require(success, "Repayment transfer failed");
        } else {
            (bool success, ) = asset.call(
                abi.encodeWithSelector(0xa9059cbb, address(this), totalRepayment)
            );
            require(success, "Repayment transfer failed");
        }

        // Update reserve
        r.totalLiquidity += premium;

        emit FlashLoanExecuted(receiver, asset, amount, premium);
        return true;
    }

    // --- View helpers ---
    function getReserve(address asset) external view returns (uint256 liquidity, uint256 borrows) {
        Reserve memory r = reserves[asset];
        return (r.totalLiquidity, r.totalBorrows);
    }

    // --- Fallback ---
    receive() external payable {}
}