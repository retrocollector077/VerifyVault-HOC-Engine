// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WrappedBTBBZ is ERC20, Ownable {
    address public bridge;

    event BridgeSet(address indexed newBridge);

    modifier onlyBridge() {
        require(msg.sender == bridge, "Not bridge");
        _;
    }

    constructor() ERC20("Wrapped BTBBZ", "wBTBBZ") {
        // No initial mint
    }

    function setBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
        emit BridgeSet(_bridge);
    }

    function mint(address to, uint256 amount) external onlyBridge {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyBridge {
        _burn(from, amount);
    }
}