pragma solidity ^0.4.20;

// simple open auction
contract SimpleAuction {
    
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    address public beneficiary;
    uint public auctionEnd;

    // Current state of the auction.
    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // Set to true at the end, disallows any change
    bool ended;

    // Events that will be fired on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // Following is natspec comment,
    // recognizable by the three slashes.
    // Will be shown when user is asked to
    // confirm a transaction.

    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    function SimpleAuction(
        uint _biddingTime,
        address _beneficiary
    ) public {
        beneficiary = _beneficiary;
        auctionEnd = now + _biddingTime;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid() public payable {
        
        // No arguments are necessary, all
        // information is already part of
        // the transaction. Keyword payable
        // required for function to receive Ether.

        // Revert call if bidding period is over.
        require(now <= auctionEnd);

        // If bid is not higher, send money back.
        require(msg.value > highestBid);

        if (highestBid != 0) {
            // Sending back money using highestBidder.send(highestBid) 
            // is security risk, it could execute an untrusted contract.
            // always safer to let recipients withdraw their money themselves.
            pendingReturns[highestBidder] += highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        HighestBidIncreased(msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // important to set this to zero because recipient can 
            // call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;

            // sends overbid amount back to sender
            // resets amount if transfer fails
            if (!msg.sender.send(amount)) {
                // resets the amount owed
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {

        // 1. Conditions
        require(now >= auctionEnd); // auction has to be over
        require(!ended); // auctionEnd must not have already been called

        // 2. Effects
        ended = true;
        AuctionEnded(highestBidder, highestBid);

        // 3. Interaction
        beneficiary.transfer(highestBid); // transfer highestBid to beneficiary
    }
}