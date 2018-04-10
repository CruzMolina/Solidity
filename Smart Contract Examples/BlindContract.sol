pragma solidity ^0.4.20;


// contract for blind auction
contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    address public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;

    // container for withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);

    modifier onlyBefore(uint _time) { require(now < _time); _; }
    modifier onlyAfter(uint _time) { require(now > _time); _; }

// initiate blind auction
    function BlindAuction(
        uint _biddingTime,
        uint _revealTime,
        address _beneficiary
    ) public {
        beneficiary = _beneficiary;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }

    /// Place a blinded (hashed) bid with `_blindedBid` = keccak256(value,
    /// fake, secret).
    /// Sent ether only refunded if bid is correctly revealed in
    /// revealing phase. The bid is valid if ether sent together
    /// with bid is at least "value" and "fake" is not true.
    /// Setting "fake" to true and sending not exact amount
    /// can hide real bid but still require deposit.
    /// The same address can place multiple bids.
    function bid(bytes32 _blindedBid)
        public
        payable
        onlyBefore(biddingEnd)
    {
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        }));
    }

    /// Bidders reveal blinded bids by sending unencrypted values. 
    /// Will get refund for all correctly blinded invalid bids and
    /// all bids except for highest bid.
    function reveal(
        uint[] _values,
        bool[] _fake,
        bytes32[] _secret
    )
        public
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        uint length = bids[msg.sender].length;
        require(_values.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            var bid = bids[msg.sender][i];
            var (value, fake, secret) =
                    (_values[i], _fake[i], _secret[i]);
            if (bid.blindedBid != keccak256(value, fake, secret)) {
                // Bid was not revealed.
                // Do not refund deposit.
                continue;
            }
            refund += bid.deposit;
            if (!fake && bid.deposit >= value) {
                if (placeBid(msg.sender, value))
                    refund -= value;
            }
            // Makes it impossible for sender to re-claim same deposit.
            bid.blindedBid = bytes32(0);
        }
        msg.sender.transfer(refund);
    }

    // internal function to check if bid was highest bidder and place
    // in pendingReturns overbid bids.
    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != 0) {
            // Refund the previously highest bidder.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            
            // stops overwithdrawal
            pendingReturns[msg.sender] = 0;

            msg.sender.transfer(amount);
        }
    }

    /// Ends auction & sends highest bid to beneficiary
    function auctionEnd()
        public
        onlyAfter(revealEnd)
    {
        require(!ended);
        AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }
}
