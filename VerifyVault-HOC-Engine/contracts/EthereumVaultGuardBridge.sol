// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "./VaultGuardNFTWrapper.sol";

interface IBridgeMessenger {
    function sendMessage(address target, bytes calldata message) external;
}

contract EthereumVaultGuardBridge {
    VaultGuardNFTWrapper public immutable wrapper;
    IBridgeMessenger public messenger;
    address public lineaBridge;

    constructor(address _wrapper, address _messenger, address _lineaBridge) {
        require(_wrapper != address(0), "Invalid wrapper address");
        require(_messenger != address(0), "Invalid messenger address");
        require(_lineaBridge != address(0), "Invalid lineaBridge address");

        wrapper = VaultGuardNFTWrapper(_wrapper);
        messenger = IBridgeMessenger(_messenger);
        lineaBridge = _lineaBridge;
    }

    event Locked(address indexed user, uint256 amount);
    event Unlocked(address indexed user, uint256 amount);

    function lockOnEthereum(uint256 amount) external {
        require(amount > 0, "Invalid amount");

        // Transfer tokens from user to this contract
        wrapper.safeTransferFrom(msg.sender, address(this), wrapper.BPL_ID(), amount, "");

        // Encode message for cross-chain communication
        bytes memory payload = abi.encode(msg.sender, amount);

        // Send message to Linea bridge via messenger
        messenger.sendMessage(lineaBridge, payload);

        emit Locked(msg.sender, amount);
    }

    function unlockFromLinea(address user, uint256 amount) external {
        require(msg.sender == address(messenger), "Only messenger can call");
        require(amount > 0, "Invalid amount");

        // Rescue tokens back to user
        wrapper.ownerRescue(user, amount);

        emit Unlocked(user, amount);
    }
}