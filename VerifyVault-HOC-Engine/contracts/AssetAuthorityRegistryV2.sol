// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IEngineAuthority {
    function hasEngineAccess(address actor) external view returns (bool);
    function hasOracleAccess(address actor) external view returns (bool);
    function hasVaultAccess(address actor) external view returns (bool);
}

/**
 * @title AssetAuthorityRegistryV2
 * @notice Central registry defining authorities, asset parameters, and access controls.
 */
contract AssetAuthorityRegistryV2 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Asset Types
    enum AssetType {
        ERC20_ASSET,
        NFT_ASSET,
        VAULT_ASSET
    }

    // Asset Record Structure
    struct AssetRecord {
        AssetType aType;
        address asset;
        uint256 ltv;        // Loan-to-value ratio (scaled, e.g., 0.3e18 for 30%)
        uint256 liqThresh;  // Liquidation threshold
        uint256 riskWeight; // Risk weight (scaled)
        bool enabled;       // Is asset enabled for use?
        bool exists;        // Does record exist?
    }

    // Storage
    mapping(bytes32 => AssetRecord) public registry;
    bytes32[] public assetList;

    // Authority Interface
    IEngineAuthority public authority;

    // Events
    event AssetRegistered(
        bytes32 indexed symbol,
        address indexed asset,
        AssetType assetType,
        uint256 ltv,
        uint256 liqThresh,
        uint256 riskWeight
    );
    event AssetUpdated(
        bytes32 indexed symbol,
        uint256 ltv,
        uint256 liqThresh,
        uint256 riskWeight
    );
    event AssetEnabled(bytes32 indexed symbol, bool enabled);
    event AssetRemoved(bytes32 indexed symbol);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifier
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
        _;
    }

    // Initializer
    function initialize(address _authority) public initializer {
        require(_authority != address(0), "Invalid authority");
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        authority = IEngineAuthority(_authority);
    }

    // Authorization for upgrade
    function _authorizeUpgrade(address impl) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // Admin functions
    function setAuthority(address _authority) external onlyAdmin {
        require(_authority != address(0), "Invalid address");
        authority = IEngineAuthority(_authority);
    }

    // Register new asset
    function registerAsset(
        bytes32 symbol,
        address asset,
        AssetType assetType,
        uint256 ltv,
        uint256 liqThresh,
        uint256 riskWeight
    ) external nonReentrant onlyAdmin {
        require(asset != address(0), "Invalid asset");
        AssetRecord storage rec = registry[symbol];
        require(!rec.exists, "Already exists");
        rec.aType = assetType;
        rec.asset = asset;
        rec.ltv = ltv;
        rec.liqThresh = liqThresh;
        rec.riskWeight = riskWeight;
        rec.enabled = true;
        rec.exists = true;
        assetList.push(symbol);
        emit AssetRegistered(symbol, asset, assetType, ltv, liqThresh, riskWeight);
    }

    // Auto-register NFT collection (from vault)
    function autoRegisterNFT(bytes32 symbol, address collection) external nonReentrant {
        require(authority.hasVaultAccess(msg.sender), "Not authorized");
        AssetRecord storage rec = registry[symbol];
        require(!rec.exists, "Exists");
        rec.aType = AssetType.NFT_ASSET;
        rec.asset = collection;
        rec.ltv = 0.3e18;        // 30% default LTV
        rec.liqThresh = 0.5e18;  // 50% liquidation threshold
        rec.riskWeight = 2e18;   // Higher risk
        rec.enabled = true;
        rec.exists = true;
        assetList.push(symbol);
        emit AssetRegistered(symbol, collection, AssetType.NFT_ASSET, rec.ltv, rec.liqThresh, rec.riskWeight);
    }

    // Update existing asset parameters
    function updateAsset(
        bytes32 symbol,
        uint256 ltv,
        uint256 liqThresh,
        uint256 riskWeight
    ) external onlyAdmin {
        AssetRecord storage rec = registry[symbol];
        require(rec.exists, "Not found");
        rec.ltv = ltv;
        rec.liqThresh = liqThresh;
        rec.riskWeight = riskWeight;
        emit AssetUpdated(symbol, ltv, liqThresh, riskWeight);
    }

    // Enable or disable asset
    function setAssetEnabled(bytes32 symbol, bool enabled) external onlyAdmin {
        AssetRecord storage rec = registry[symbol];
        require(rec.exists, "Not found");
        rec.enabled = enabled;
        emit AssetEnabled(symbol, enabled);
    }

    // Remove asset (optional)
    function removeAsset(bytes32 symbol) external onlyAdmin {
        AssetRecord storage rec = registry[symbol];
        require(rec.exists, "Not found");
        rec.exists = false;
        rec.enabled = false;
        emit AssetRemoved(symbol);
    }

    // View functions
    function getAsset(bytes32 symbol) external view returns (AssetRecord memory) {
        require(registry[symbol].exists, "Not found");
        return registry[symbol];
    }

    function getAllSymbols() external view returns (bytes32[] memory) {
        return assetList;
    }

    // Transfer ownership (if needed)
    function transferOwnership(address newOwner) external onlyAdmin {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner(), newOwner);
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner); // Assign admin role to new owner
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
