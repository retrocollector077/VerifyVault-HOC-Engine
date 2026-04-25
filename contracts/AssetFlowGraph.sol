// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/**
 * @title AssetFlowGraph with Fees and Owner Control
 * @notice Manages a directed graph of assets, with fee support and a hardcoded fee recipient.
 */
contract AssetFlowGraph {
    // Struct to store edge info with fee
    struct EdgeInfo {
        uint256 feeBps; // fee in basis points (e.g., 100 = 1%)
        bool exists;
    }

    // Mapping from node to list of connected nodes
    mapping(bytes32 => bytes32[]) public edges;

    // Mapping for edge info (from -> to)
    mapping(bytes32 => mapping(bytes32 => EdgeInfo)) public edgeDetails;

    // Owner for access control
    address public owner;

    // Hardcoded fee recipient address
    address public constant feeRecipient = 0x8B8143864297858b81d02b76dF2a5C1824eA01E8;

    // Events
    event EdgeAdded(bytes32 indexed from, bytes32 indexed to, uint256 feeBps);
    event EdgeRemoved(bytes32 indexed from, bytes32 indexed to);
    event FeeUpdated(bytes32 indexed from, bytes32 indexed to, uint256 newFeeBps);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Set fee for an existing or new edge
    function setEdgeFee(bytes32 from, bytes32 to, uint256 feeBps) external onlyOwner {
        require(feeBps <= 10000, "Fee too high");
        edgeDetails[from][to].feeBps = feeBps;
        edgeDetails[from][to].exists = true;
        emit FeeUpdated(from, to, feeBps);
    }

    // Add an edge with specified fee
    function link(bytes32 from, bytes32 to, uint256 feeBps) external onlyOwner {
        require(feeBps <= 10000, "Fee too high");
        edges[from].push(to);
        edgeDetails[from][to] = EdgeInfo({feeBps: feeBps, exists: true});
        emit EdgeAdded(from, to, feeBps);
    }

    // Remove an edge
    function removeEdge(bytes32 from, bytes32 to) external onlyOwner {
        // Remove edge from edges array
        bytes32[] storage arr = edges[from];
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == to) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                delete edgeDetails[from][to];
                emit EdgeRemoved(from, to);
                break;
            }
        }
    }

    // Get edges from a node
    function getEdges(bytes32 from) external view returns (bytes32[] memory) {
        return edges[from];
    }

    // Get fee for specific edge
    function getEdgeFee(bytes32 from, bytes32 to) external view returns (uint256) {
        return edgeDetails[from][to].feeBps;
    }

    // Transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
