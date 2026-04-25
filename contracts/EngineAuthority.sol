// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title EngineAuthority
 * @notice Central permission registry for Omega v7 system modules.
 *         Validates execution rights for subsystems.
 * @dev Roles:
 * - DEFAULT_ADMIN_ROLE: Full authority, can grant/revoke.
 * - ENGINE_ROLE: Arbitrage, liquidation, core.
 * - ROUTER_ROLE: Swap/bridge router.
 * - ORACLE_ROLE: Oracle feeders.
 * - VAULT_ROLE: Vaults, NFT vaults, BTBBZ vault.
 * - LIQUIDATOR_ROLE: Liquidation bots.
 * - FLASHLOAN_ROLE: Flashloan providers.
 * - OFFRAMP_ROLE: USDC off-ramp.
 */
contract EngineAuthority is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    // Role definitions
    bytes32 public constant ENGINE_ROLE = keccak256("ENGINE_ROLE");
    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    bytes32 public constant FLASHLOAN_ROLE = keccak256("FLASHLOAN_ROLE");
    bytes32 public constant OFFRAMP_ROLE = keccak256("OFFRAMP_ROLE");

    // Events
    event RoleGranted(address indexed actor, bytes32 role);
    event RoleRevoked(address indexed actor, bytes32 role);

    /**
     * @notice Initialize the contract with an admin address
     * @param admin Address of the initial admin with all permissions
     */
    function initialize(address admin) public initializer {
        require(admin != address(0), "Invalid admin address");
        __AccessControlUpgradeable_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        emit RoleGranted(admin, DEFAULT_ADMIN_ROLE);
    }

    /**
     * @dev Authorization for upgradeability
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // --- Role granting functions ---
    function grantEngine(address actor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ENGINE_ROLE, actor);
        emit RoleGranted(actor, ENGINE_ROLE);
    }

    function grantRouter(address actor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ROUTER_ROLE, actor);
        emit RoleGranted(actor, ROUTER_ROLE);
    }

    function grantOracle(address actor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ORACLE_ROLE, actor);
        emit RoleGranted(actor, ORACLE_ROLE);
    }

    function grantVault(address actor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(VAULT_ROLE, actor);
        emit RoleGranted(actor, VAULT_ROLE);
    }

    function grantLiquidator(address actor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(LIQUIDATOR_ROLE, actor);
        emit RoleGranted(actor, LIQUIDATOR_ROLE);
    }

    function grantFlashLoan(address actor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(FLASHLOAN_ROLE, actor);
        emit RoleGranted(actor, FLASHLOAN_ROLE);
    }

    function grantOffRamp(address actor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(OFFRAMP_ROLE, actor);
        emit RoleGranted(actor, OFFRAMP_ROLE);
    }

    // --- Role revocation ---
    function revokeRoleFrom(address actor, bytes32 role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, actor);
        emit RoleRevoked(actor, role);
    }

    // --- View functions ---
    function hasEngineAccess(address actor) external view returns (bool) {
        return hasRole(ENGINE_ROLE, actor);
    }

    function hasRouterAccess(address actor) external view returns (bool) {
        return hasRole(ROUTER_ROLE, actor);
    }

    function hasOracleAccess(address actor) external view returns (bool) {
        return hasRole(ORACLE_ROLE, actor);
    }

    function hasVaultAccess(address actor) external view returns (bool) {
        return hasRole(VAULT_ROLE, actor);
    }

    function hasLiquidatorAccess(address actor) external view returns (bool) {
        return hasRole(LIQUIDATOR_ROLE, actor);
    }

    function hasFlashLoanAccess(address actor) external view returns (bool) {
        return hasRole(FLASHLOAN_ROLE, actor);
    }

    function hasOffRampAccess(address actor) external view returns (bool) {
        return hasRole(OFFRAMP_ROLE, actor);
    }
}