pragma solidity ^0.4.18;

// Voting contract. 

contract Voting {

  // map candidate name (bytes 32) to vote count (uint8)
  mapping (bytes32 => uint8) public votesReceived;
  
  // empty array to store list of candidate names
  bytes32[] public candidateList;

  // call once after deploying contract to blockchain
  // passes array of candidate names onto the blockchain
  function Voting(bytes32[] candidateNames) public {
    candidateList = candidateNames;
  }

  // returns the total votes a candidate has received so far
  function totalVotesFor(bytes32 candidate) view public returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  // increases vote count for a specified candidate
  // equivalent to casting a vote
  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }
  

  // function used to check if specified candidate
  // is a valid candidate in candidateList
  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}