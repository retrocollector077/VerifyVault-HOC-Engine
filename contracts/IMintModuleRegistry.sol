// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title MintModuleRegistry
 * @notice Upgradeable registry for mint modules with registration control.
 */
contract MintModuleRegistry is IMintModuleRegistry, OwnableUpgradeable, UUPSUpgradeable {
    // Mapping to track registered modules
    mapping(address => bool) private _registeredModules;

    // Events (from interface)
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);

    // Initializer for upgradeable pattern
    function initialize() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // Authorization for upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Registers a new module if not already registered.
     */
    function registerModule(address module) external override onlyOwner {
        if (module == address(0)) revert InvalidAddress();
        if (_registeredModules[module]) revert AlreadyRegistered();

        _registeredModules[module] = true;
        emit ModuleAdded(module);
    }

    /**
     * @notice Unregisters a module if it exists.
     */
    function unregisterModule(address module) external override onlyOwner {
        if (module == address(0)) revert InvalidAddress();
        if (!_registeredModules[module]) revert NotRegistered();

        _registeredModules[module] = false;
        emit ModuleRemoved(module);
    }

    /**
     * @notice Checks if a module is registered.
     */
    function isRegistered(address module) external view override returns (bool) {
        return _registeredModules[module];
    }
}