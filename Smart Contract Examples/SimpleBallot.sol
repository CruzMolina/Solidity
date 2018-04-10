pragma solidity ^0.4.16;

/// Voting with delegation.
contract Ballot {
    
    // Structure for each voter.
    struct Voter {
        
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }

    // Structure for each proposal.
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;
    
    // Maps a voter struct to each possible address.
    mapping(address => Voter) public voters;

    // Dynamically-sized array of Proposal structs.
    Proposal[] public proposals;

    /// Creates a new ballot for a given set of proposals.
    function CreateBallot(bytes32[] proposalNames) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // For loop that runs through each proposal and
        // creates a new temporary object to add/fill-in 
        // the proposals array.
        for (uint i = 0; i < proposalNames.length; i++) {
            
            // `Proposal({...})` creates a temporary
            // Proposal object and `proposals.push(...)`
            // appends it to the end of proposals.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // Function to delegate voting rights for a given ballot.
    // May only be called by chairperson.
    function giveRightToVote(address voter) public {
        
        // If the argument of `require` evaluates to `false`,
        // it terminates & reverts all changes to the state
        // & to Ether balances. Currently, this will consume
        // all provided gas.
        require(
            (msg.sender == chairperson) &&
            !voters[voter].voted &&
            (voters[voter].weight == 0)
        );
        voters[voter].weight = 1;
    }

    // Function to check if msg.sender's voting rights
    // can be transferred to another voter.
    function InitiateDelegation(address to) public {
        
        // assigns reference for sender
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);

        // Self-delegation not allowed.
        require(to != msg.sender);

        // Checks if "to" voter delegated their vote to another address.
        // First checks if they haven't.
        if (voters[to].delegate == address(0)) {
            
            // Calls DelegationSuccess to complete delegation process
            CompleteDelegation(to, msg.sender);
            
        } else {
            
            // Since "to" delegated vote to another address, checks
            // to ensure the delegation is not to the original delegator/sender.
            // If true, delegation process cancelled.
            require(voters[to].delegate != msg.sender);
            
            // Delegation was found to be to another address.
            // Forwards that address to DelegationSuccess to
            // complete the delegation process.
            to = voters[to].delegate;
            CompleteDelegation(to, msg.sender);
        }
    }
    
    
    // Completes Delegation process after IniateDelegation verified validity
    function CompleteDelegation(address to, address sender) private {

        // assigns reference for delegator/sender
        Voter storage delegator = voters[sender];
        
        // Sender gives up voting right to delegate.
        delegator.voted = true;
        delegator.delegate = to;
        Voter storage delegate_ = voters[to];
        
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += delegator.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += delegator.weight;
        }
    }

    /// Function to vote (w/ any votes delegated)
    /// for a given proposal (`proposals[proposal].name`).
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` given is not valid (out of the range of the array),
        // will throw automatically and revert all changes
        proposals[proposal].voteCount += sender.weight;
    }

    /// Computes the winning proposal by taking all
    /// previous votes into account. Returns winning proposal
    function winningProposal() public view returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    function winnerName() public view returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}