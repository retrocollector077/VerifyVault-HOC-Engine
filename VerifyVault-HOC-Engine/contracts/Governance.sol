// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable {
    struct Proposal {
        address proposer;
        bytes callData;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public hasVoted;

    event ProposalCreated(uint256 id, address proposer);
    event Voted(uint256 proposalId, bool support, address voter);
    event ProposalExecuted(uint256 id);

    function propose(bytes calldata data) external onlyOwner {
        proposalCount += 1;
        proposals[proposalCount] = Proposal({
            proposer: msg.sender,
            callData: data,
            votesFor: 0,
            votesAgainst: 0,
            endTime: block.timestamp + 3 days,
            executed: false
        });
        emit ProposalCreated(proposalCount, msg.sender);
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp < p.endTime, "Voting ended");
        require(!hasVoted[msg.sender], "Already voted");
        hasVoted[msg.sender] = true;
        if (support) {
            p.votesFor += 1;
        } else {
            p.votesAgainst += 1;
        }
        emit Voted(proposalId, support, msg.sender);
    }

    function execute(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.endTime, "Voting not ended");
        require(!p.executed, "Already executed");
        require(p.votesFor > p.votesAgainst, "Not approved");
        (bool success, ) = address(this).call(p.callData);
        require(success, "Execution failed");
        p.executed = true;
        emit ProposalExecuted(proposalId);
    }
}