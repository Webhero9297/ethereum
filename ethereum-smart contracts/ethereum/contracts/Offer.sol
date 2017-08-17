pragma solidity ^0.4.0;
import "./usingOraclize.sol";

contract Offer is usingOraclize {

    uint public Odds;
    uint public Coverage;
    uint public RemainingCoverage;
    uint public CloseDate;
    uint public LockDate;
    
    address private OfferAddress;
    address private HouseAddress;
    string private OfferHash;
    uint private HouseRatio;

    mapping(address => uint) private Bids;
    mapping(uint => address) private BidIterator;
    uint private BidCount;

    event newOraclizeQuery(string description);
    event initialized();
    event bidWin(uint houseAmount);
    event newBid(uint amount, address bidder);
    event sellWin(uint amount, uint houseAmount);

    function Offer(uint _odds, uint _coverage,
                 address _offerAddr, string _offerHash,
                 address _houseAddr, uint8 _houseRatio) payable {
        // Comment the following out in production
        // this is only for testing Oraclize.it using testrpc
        // OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);        Odds = _odds;
        Coverage = _coverage;
        RemainingCoverage = _coverage;
        OfferAddress = _offerAddr;
        OfferHash = _offerHash;
        HouseAddress = _houseAddr;
        HouseRatio = _houseRatio;
        initialized();
    }

    function stringToUint(string s) constant returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) throw;
        uint256 housePayback = 0;
        uint resultVal = stringToUint(result);
        if (resultVal == 0) { // no update
        
        } else if (resultVal == 1) { // bid win
            CloseDate = now;
            uint256 totalHousePayback = 0;
            for (uint i = 0; i < BidCount; i++) {
                var addr = BidIterator[i];
                var value = Bids[addr];
                var bidPayback = (100 - HouseRatio) * (value * Odds) / 100;
                housePayback = (value * Odds) - bidPayback;
                var bidPaybackResult = addr.send(bidPayback);
                if (!bidPaybackResult) throw;
                var housePaybackResult = HouseAddress.send(housePayback);
                if (!housePaybackResult) throw;
                totalHousePayback += housePayback;
            }
            bidWin(housePayback);
        } else if (resultVal == 2) { // sell win
            CloseDate = now;
            var sellPayback = (100 - HouseRatio) * (Coverage - RemainingCoverage) / 100;
            housePayback =  (Coverage - RemainingCoverage) - sellPayback;
            var sellPaybackResult = OfferAddress.send(sellPayback);
            if (!sellPaybackResult) throw;
            var housePaybackResult2 = HouseAddress.send(housePayback);
            if (!housePaybackResult2) throw;
            sellWin(sellPayback, housePayback);
        } else {
            throw;
        }
    }
    
    function bid() payable {
        if (CloseDate != 0 && now > CloseDate) throw;
        if (msg.value > RemainingCoverage) throw;
        var addr = msg.sender;
        Bids[addr] += msg.value;
        BidIterator[BidCount] = addr;
        BidCount++;
        RemainingCoverage -= msg.value;
        newBid(msg.value, msg.sender);
    }

    function update() payable {
        newOraclizeQuery("Dispatching query to betyahq via oraclize...");
        var url_base = "json(https://betya.herokuapp.com/api/win?offer_hash=";
        // strings in solidity fucking SUCK
        oraclize_query(3600, "URL", strConcat(url_base, OfferHash, ").win"));
    }
    
}
