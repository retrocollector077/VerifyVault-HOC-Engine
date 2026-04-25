
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface ILineaBridge {
    function bridgeMessage(
        uint256 _fee,
        address _to,
        uint256 _value,
        bytes calldata _calldata
    ) external payable;
}

contract LineaBridge is ILineaBridge {
    // Hardcoded payout address (verifyvault.eth resolved)
    address public constant payoutAddress = 0xb71CAb9c1C2fEC09Ed84269dA6353Fb0a19CFf8d;

    // Admin address (could be owner, for simplicity we use owner pattern)
    address public owner;

    // Fee percentage (basis points, default 0)
    uint16 public feeBps;

    // Events
    event BridgeMessage(address indexed sender, address indexed to, uint256 value, uint256 fee, bytes calldata);
    event FeeUpdated(uint16 newFeeBps);
    event FeesWithdrawn(address to, uint256 amount);
    event OwnershipTransferred(address previousOwner, address newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Set fee basis points (max 10000 = 100%)
    function setFeeBps(uint16 _feeBps) external onlyOwner {
        require(_feeBps <= 10000, "Max 100%");
        feeBps = _feeBps;
        emit FeeUpdated(_feeBps);
    }

    // Bridge message implementation
    function bridgeMessage(
        uint256 _fee,
        address _to,
        uint256 _value,
        bytes calldata _calldata
    ) external payable override {
        require(msg.value >= _fee, "Insufficient fee");
        uint256 remaining = msg.value - _fee;

        // Forward fee to payout address
        (bool feeSent, ) = payoutAddress.call{value: _fee}("");
        require(feeSent, "Fee transfer failed");

        // Forward remaining ETH to the recipient
        (bool success, ) = _to.call{value: remaining}(_calldata);
        require(success, "Call failed");

        emit BridgeMessage(msg.sender, _to, _value, _fee, _calldata);
    }

    // Owner can withdraw accumulated ETH (if any)
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = payoutAddress.call{value: amount}("");
        require(success, "Withdrawal failed");
        emit FeesWithdrawn(payoutAddress, amount);
    }

    // Transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Fallback to accept ETH
    receive() external payable {}
}