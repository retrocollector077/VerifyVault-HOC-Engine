// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/**
 * @title IOracleHub
 * @notice Interface for a price oracle system.
 */
interface IOracleHub {
    /**
     * @notice Retrieves the latest price for a given asset.
     * @param asset The address of the asset.
     * @return The latest price of the asset.
     */
    function getPrice(address asset) external view returns (uint256);
}

/**
 * @title OracleFeeRouter
 * @notice Contract to fetch prices and handle fee collection routed to a fixed payout address.
 */
contract OracleFeeRouter {
    // Hardcoded payout address (replace with your actual address)
    address public constant payoutAddress = 0xb71CAb9c1C2fEC09Ed84269dA6353Fb0a19CFf8d;

    // Fee basis points (max 10000 = 100%)
    uint16 public feeBps;

    // External oracle
    IOracleHub public oracle;

    // Events
    event FeeUpdated(uint16 newFeeBps);
    event PriceFetched(address indexed asset, uint256 price);
    event FeeCollected(address indexed from, uint256 amount);
    event FeesWithdrawn(address indexed to, uint256 amount);

    /**
     * @param _oracle Address of the deployed oracle system
     * @param _initialFeeBps Initial fee basis points
     */
    constructor(address _oracle, uint16 _initialFeeBps) {
        require(_oracle != address(0), "Invalid oracle address");
        oracle = IOracleHub(_oracle);
        require(_initialFeeBps <= 10000, "Fee cannot exceed 100%");
        feeBps = _initialFeeBps;
    }

    /**
     * @notice Sets a new fee rate (basis points)
     * @param _newFeeBps New fee basis points
     */
    function setFeeBps(uint16 _newFeeBps) external {
        require(msg.sender == address(this) || msg.sender == owner(), "Not authorized");
        require(_newFeeBps <= 10000, "Max 100%");
        feeBps = _newFeeBps;
        emit FeeUpdated(_newFeeBps);
    }

    /**
     * @notice Fetches the latest price for an asset
     * @param asset The address of the asset
     * @return The latest price
     */
    function getPrice(address asset) external returns (uint256) {
        uint256 price = oracle.getPrice(asset);
        require(price > 0, "Invalid price");
        emit PriceFetched(asset, price);
        return price;
    }

    /**
     * @notice Collects fee in tokens from user and routes to payout address
     * @param token The token address
     * @param amount The amount to transfer
     */
    function collectFee(address token, uint256 amount) external {
        uint256 feeAmount = (amount * feeBps) / 10000;
        require(IERC20(token).transferFrom(msg.sender, payoutAddress, feeAmount), "Transfer failed");
        emit FeeCollected(msg.sender, feeAmount);
    }

    /**
     * @notice Owner can withdraw ETH accumulated in contract
     * @param amount Amount of ETH to withdraw
     */
    function withdrawETH(uint256 amount) external {
        require(msg.sender == owner(), "Not owner");
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = payoutAddress.call{value: amount}("");
        require(success, "Withdrawal failed");
        emit FeesWithdrawn(payoutAddress, amount);
    }

    /**
     * @notice Fallback to accept ETH
     */
    receive() external payable {}

    /**
     * @notice Owner function for transfer (for upgradeability or admin)
     */
    function owner() public view returns (address) {
        return address(0); // Replace with your owner logic if needed
    }
}