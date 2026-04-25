
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Ownable} from "solady/auth/Ownable.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

contract AssetAuthorityRegistry is Ownable {
    // Hardcoded payout address (verifyvault.eth resolved)
    address public constant payoutAddress = 0xb71CAb9c1C2fEC09Ed84269dA6353Fb0a19CFf8d;

    // Enum for asset types
    enum AssetType {
        UNKNOWN,
        ERC20,
        ERC721,
        VAULT,
        ORACLE
    }

    // Structs
    struct AssetRecord {
        AssetType assetType;
        address assetAddress;
        string symbol;
        string name;
        uint8 decimals;
        uint256 timestamp;
        bool active;
    }

    struct OracleRecord {
        address oracle;
        bool active;
    }

    struct VaultRecord {
        address vault;
        address underlyingAsset;
        bool active;
    }

    // Storage
    uint256 public totalAssets;
    mapping(uint256 => AssetRecord) public assets;             // assetId -> AssetRecord
    mapping(address => uint256) public assetIdOf;              // reverse lookup
    mapping(address => OracleRecord) public oracleOf;          // asset -> Oracle
    mapping(address => VaultRecord) public vaultOf;            // underlying asset -> Vault
    mapping(address => bool) public authorizedModule;        // modules authorized

    // Fee basis points (owner can set)
    uint16 public feeBps = 0; // default 0, max 10000 (100%)

    // Accumulated fees (in USDC or ETH, depending on context)
    uint256 public accumulatedFees;

    // Events
    event AssetRegistered(uint256 indexed assetId, address indexed asset, AssetType assetType, string symbol, string name);
    event AssetStatusUpdated(uint256 indexed assetId, bool active);
    event OracleLinked(address indexed asset, address indexed oracle);
    event VaultLinked(address indexed underlying, address indexed vault);
    event ModuleAuthorized(address indexed module, bool enabled);
    event FeeUpdated(uint16 newFeeBps);
    event FeesWithdrawn(address to, uint256 amount);

    // Modifiers
    modifier onlyAuthorized() {
        require(owner() == msg.sender || authorizedModule[msg.sender], "Not authorized");
        _;
    }

    // Admin: authorize modules
    function authorizeModule(address module, bool enabled) external onlyOwner {
        authorizedModule[module] = enabled;
        emit ModuleAuthorized(module, enabled);
    }

    // Set fee basis points (max 10000)
    function setFeeBps(uint16 newBps) external onlyOwner {
        require(newBps <= 10000, "Max 100%");
        feeBps = newBps;
        emit FeeUpdated(newBps);
    }

    // Register ERC20 token
    function registerERC20(address token) external onlyAuthorized returns (uint256) {
        require(token != address(0), "Zero address");
        require(assetIdOf[token] == 0, "Already registered");
        string memory name = _tryName(token);
        string memory symbol = _trySymbol(token);
        uint8 decimals = _tryDecimals(token);
        uint256 id = ++totalAssets;
        assets[id] = AssetRecord({
            assetType: AssetType.ERC20,
            assetAddress: token,
            symbol: symbol,
            name: name,
            decimals: decimals,
            timestamp: block.timestamp,
            active: true
        });
        assetIdOf[token] = id;
        return id;
    }

    // Register ERC721 collection
    function registerERC721(address collection) external onlyAuthorized returns (uint256) {
        require(collection != address(0), "Zero address");
        require(assetIdOf[collection] == 0, "Already registered");
        string memory name = _tryName(collection);
        string memory symbol = _trySymbol(collection);
        uint256 id = ++totalAssets;
        assets[id] = AssetRecord({
            assetType: AssetType.ERC721,
            assetAddress: collection,
            symbol: symbol,
            name: name,
            decimals: 0,
            timestamp: block.timestamp,
            active: true
        });
        assetIdOf[collection] = id;
        return id;
    }

    // Link vault
    function registerVault(address vault, address underlying) external onlyAuthorized {
        require(vault != address(0) && underlying != address(0), "Zero address");
        vaultOf[underlying] = VaultRecord({vault: vault, underlyingAsset: underlying, active: true});
        emit VaultLinked(underlying, vault);
    }

    // Link oracle
    function registerOracle(address asset, address oracle) external onlyAuthorized {
        require(asset != address(0) && oracle != address(0), "Zero address");
        oracleOf[asset] = OracleRecord({oracle: oracle, active: true});
        emit OracleLinked(asset, oracle);
    }

    // Helper: get name, symbol, decimals
    function _tryName(address token) internal view returns (string memory) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("name()"));
        if (success) return abi.decode(data, (string));
        return "";
    }

    function _trySymbol(address token) internal view returns (string memory) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("symbol()"));
        if (success) return abi.decode(data, (string));
        return "";
    }

    function _tryDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("decimals()"));
        if (success) return abi.decode(data, (uint8));
        return 0;
    }

    // Withdraw accumulated fees (assuming in ETH, could be token if needed)
    function withdrawFees(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = payoutAddress.call{value: amount}("");
        require(success, "Withdrawal failed");
        emit FeesWithdrawn(payoutAddress, amount);
    }

    // Optionally, receive ETH
    receive() external payable {}
}