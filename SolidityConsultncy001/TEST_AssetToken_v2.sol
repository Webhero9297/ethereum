pragma solidity ^0.4.11;

/**
* TEST_AssetToken_v2.sol creates an asset-backed token for sale, includes administrative features for redemption of tokens for
*   the underlying asset and creates a DAO to manage the token fees and payout dividends to DAO members
*   Crowdsale contracts edited from original contract code at https://www.ethereum.org/crowdsale#crowdfund-your-idea
*   Additional crowdsale contracts, functions, libraries from OpenZeppelin
*       at https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts/token
*   Token contract edited from original contract code at https://www.ethereum.org/token
*   ERC20 interface and certain token functions adapted from https://github.com/ConsenSys/Tokens
**/


contract ERC20 {
	//Sets events and functions to comply with ERC20
	event Approval(address indexed _owner, address indexed _spender, uint _value);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	
    function allowance(address _owner, address _spender) constant returns (uint remaining);
	function approve(address _spender, uint _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
}


library SafeMath {
    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }  

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
  
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}


contract Authorizable {
    //Applies SafeMath library to uint256 operations 
    using SafeMath for uint256;

	//Sets arrays 
	address[] authorizers;
	mapping(address => bool) authorizerIndex;

	//Requires sender to function be authorized 
	modifier onlyAuthorized {
		require(isAuthorized(msg.sender));
		_;
	}

	//Initializes contract with sender as authorized 
	function Authorizable() {
		authorizers.length = 2;
		authorizers[1] = msg.sender;
		authorizerIndex[msg.sender] = true;
	}
	
	//Adds a new authorizer
	function addAuthorized(address _addr) external onlyAuthorized {
		authorizerIndex[_addr] = true;
		authorizers.length++;
		authorizers[authorizers.length.sub(1)] = _addr;
	}

	//Returns the address of a specific index
	function getAuthorizer(uint authorizerIndex) external constant returns(address) {
		return address(authorizers[authorizerIndex.add(1)]);
	}

	//Returns whether an address is authorized 
	function isAuthorized(address _addr) constant returns(bool success) {
		if (authorizerIndex[_addr] == true) {
			return true; 
		}
		return false; 
	}
	
	//Removes an authorized account
	function removeAuthorized(address _addr) external onlyAuthorized returns(bool success) {
        authorizerIndex[_addr] = false; 
		for (uint i = 0; i < (authorizers.length.sub(1)); i++)
            if (authorizers[i] == _addr) {
                authorizers[i] = authorizers[authorizers.length.sub(1)];
                break;
            }
        authorizers.length -= 1;
        return true; 
	}
}


contract Owned {
	//Public variable
    address public owner;

	//Sets contract creator as the owner
    function Owned() {
        owner = msg.sender;
    }
	
	//Sets onlyOwner modifier for specified functions
    modifier onlyOwner {
		require(isOwner(msg.sender));
		_;
    }

	//Returns whether an address is the owner
	function isOwner(address _addr) constant returns(bool success) {
		if (_addr == owner) {
			return true; 
		}
		return false; 
	}

	//Allows for transfer of contract ownership
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract AssetToken is ERC20, Owned {
    //Applies SafeMath library to uint256 operations 
    using SafeMath for uint256;

	//Public variables
    mapping (address => bool) public frozenAccount;
	string public name; 
	string public symbol; 
	uint8 public decimals;
    uint256 public initialSupply;  
	uint256 public totalSupply; 
    
    //Variables
    uint256 multiplier; 

    //Events
    event FrozenFunds(address target, bool frozen);
	
	//Creates arrays for balance and approval 
    mapping (address => uint256) balance;
    mapping (address => mapping (address => uint256)) allowed;

    //Creates modifier to prevent short address attack
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) revert();
        _;
    }
	
	function AssetToken(string tokenName, string tokenSymbol, uint8 decimalUnits, uint256 initialSupply) {
		name = tokenName; 
		symbol = tokenSymbol; 
		decimals = decimalUnits; 
		totalSupply = initialSupply; 
	}
	
	//Provides the remaining balance of approved tokens from function approve 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

	//Allows for a certain amount of tokens to be spent on behalf of the account owner
    function approve(address _spender, uint256 _value) returns (bool success) { 
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

	//Returns the account balance 
    function balanceOf(address _owner) constant returns (uint256) {
        return balance[_owner];
    }

    //Freezes specified account
	function freezeAccount(address target, bool freeze) onlyOwner {
		frozenAccount[target] = freeze;
		FrozenFunds(target, freeze);
	}

	//Sends tokens from sender's account
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
		if (frozenAccount[msg.sender]) revert(); 
        if ((balance[msg.sender] >= _value) && (balance[_to].add(_value) > balance[_to])) {
            balance[msg.sender] -= _value;
            balance[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { 
			return false; 
		}
    }
	
	//Transfers tokens an approved account 
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
		if (frozenAccount[_from]) revert(); 
        if ((balance[_from] >= _value) && (allowed[_from][msg.sender] >= _value) && (balance[_to].add(_value) > balance[_to])) {
            balance[_to] += _value;
            balance[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { 
			return false; 
		}
    }
}


contract AssetTokenSale is Authorizable, Owned, AssetToken {
    //Applies SafeMath library to uint256 operations 
    using SafeMath for uint256;

    //Public Variables
    address public multiSigWallet;  
    address public redemptionWallet; 
    bool public saleClosed = true;   
    uint256 public dividendPayment;              
    uint256 public price; 
    uint256 public startTime; 
    uint256 public stopTime; 
    uint256 public tokenSaleFee; 

    //Variables  
    address[] tokenHolders;     
    mapping (address => uint256) tokenHolderID; 
    uint256 initialTokens; 
    uint256 multiplier = 1000000; 
    uint8 decimalUnits = 6; 

    //Events
    event DestroyTokens(address indexed _from, address indexed _to, uint256 _value);
    event RedeemTokens(address indexed _from, address indexed _to, uint256 _value); 
	
	//Initializes the token
	function AssetTokenSale(string tokenName, string tokenSymbol, uint256 initialAmount, address tokenSaleMultiSigWallet, address orderProcessWallet) 
		AssetToken(tokenName, tokenSymbol, decimalUnits, initialAmount) {
            multiSigWallet = tokenSaleMultiSigWallet;
            redemptionWallet = orderProcessWallet; 
			initialTokens = initialAmount.mul(multiplier); 
            balance[multiSigWallet] = initialTokens;  
            Transfer(0, msg.sender, initialTokens);                                         
    } 
	
    //Fallback function creates tokens and sends to investor when sales are permitted
    function () payable {
        require(!saleClosed); 
        address recipient = msg.sender; 
        uint256 tokens = msg.value.mul(getPrice()).mul(multiplier).div(1 ether);
        totalSupply = totalSupply.add(tokens);
        balance[recipient] = balance[recipient].add(tokens);
        require(multiSigWallet.send(msg.value)); 
        Transfer(0, recipient, tokens);
    }  
	
	//Allows contract owner to create new tokens, prevents numerical overflow
	function createToken(address target, uint256 createdAmount) onlyAuthorized returns (bool success) {
		if ((totalSupply.add(createdAmount)) < totalSupply) {
			revert(); 
		} else {
			balance[target] += createdAmount;
			totalSupply += createdAmount;
			Transfer(msg.sender, target, createdAmount);
			return true; 
		}
	}
	
	//Allows contract owner to create new tokens, prevents numerical overflow
	function destroyToken(address target, uint256 destroyedAmount) onlyAuthorized returns (bool success) {
		if ((totalSupply.sub(destroyedAmount)) > totalSupply) {
			revert(); 
		} else {
			balance[target] -= destroyedAmount;
			totalSupply -= destroyedAmount;
			DestroyTokens(msg.sender, target, destroyedAmount);
			return true; 
		}
	}

    //Returns the current price of the token for the crowdsale
    function getPrice() returns (uint256) {
        return price;
    }

    //Sends tokens from sender's account to the redemption wallet
    function redeemTokens(uint256 amount) returns (bool success) {
		if (frozenAccount[msg.sender]) revert(); 
        if ((balance[msg.sender] >= amount) && (balance[redemptionWallet].add(amount) > balance[redemptionWallet])) {
            balance[msg.sender] -= amount;
            balance[redemptionWallet] += amount;
            Transfer(msg.sender, redemptionWallet, amount);
            uint256 redemptionFee = amount.mul(tokenSaleFee).div(100); 
            uint256 redemptionTotal = amount.sub(redemptionFee); 
            RedeemTokens(0, msg.sender, redemptionTotal); 
            return true;
        } else { 
			return false; 
		}
    }

    //Sets the multisig wallet for a crowdsale
    function setMultiSigWallet(address wallet) onlyOwner returns (bool success) {
        multiSigWallet = wallet; 
        return true; 
    }

    //Sets the token price 
    function setPrice(uint256 newPriceperEther) onlyOwner returns (uint256) {
        require(newPriceperEther > 0); 
        price = newPriceperEther; 
        return price; 
    }

    //Allows owner to start the crowdsale from the time of execution until a specified stopTime
    function startSale(uint256 price, uint256 saleStart, address tokenWallet) onlyOwner returns (bool success) {    
        saleClosed = false; 
        startTime = saleStart; 
        setPrice(price); 
        return true; 
    }

    //Allows owner to stop the crowdsale immediately
    function stopSale() onlyOwner returns (bool success) {
        stopTime = now; 
        saleClosed = true;
        return true; 
    }
}

contract Member is AssetToken {
    //Applies SafeMath library to uint256 operations 
    using SafeMath for uint256;

	//Sets variables, event
	address[] public members;
    uint256 public numMembers; 
	mapping(address => uint256) memberID;
    event MembershipChanged(address member, bool isMember);

	//Requires sender to a function be a member 
	modifier onlyMember {
		require(isMember(msg.sender));
		_;
	}

	//Initializes contract with sender a member
	function Member() {
		members.length = 2;
		members[1] = msg.sender;
		memberID[msg.sender] = true;
        numMembers = 1; 
	}

    //Adds members to the dao 
    function addMember(address account) internal {
        uint256 id;
        if (memberID[account] == 0) {
           memberID[account] = members.length;
           id = members.length++;
           numMembers++;
        } else {
            revert(); 
        }
        MembershipChanged(account, true);
    }  

    //Allows an account to apply for membership in the dao based on holding tokens of target contract
    function applyMembership(address account) returns (bool success) {
        bool member = false; 
        if (checkOwnership(account) == true) {
            addMember(account); 
            member = true; 
        }
        return member; 
    }

    //Checks whether a member still holds a balance of the contract tokens
    function checkOwnership(address account) returns (bool success) {
        bool status = false;
        if (balanceOf(account) > multiplier.mul(15000)) {
            status = true; 
        }
        else {
            removeMember(account); 
        }
        return status; 
    }

    //Checks whether each member still holds a balance of the contract tokens
    function checkOwnerships() returns (bool success) {
        for (uint i = 0; i < (members.length.sub(1)); i++) {
            checkOwnership(members[i]); 
        }
        return true; 
    }

	//Returns the address of a specific index value
	function getMember(uint256 memberID) constant returns (address) {
		return address(members[memberID.add(1)]);
	}

	//Returns whether an address is a member 
	function isMember(address account) constant returns (bool success) {
		if (memberID[account] == true) {
			return true; 
		}
		return false; 
	}
	
	//Removes a member's account
	function removeMember(address account) internal {
        require(memberID[account] != 0);
        for (uint256 i = memberID[account]; i < (members.length.sub(1)); i++) {
            members[i] = members[i.add(1)];
        }
        delete members[members.length.sub(1)];
        members.length--;
        numMembers--; 
        MembershipChanged(account, false);
	}
}


contract AssetDAO is Owned, AssetTokenSale, Member {
    //Applies SafeMath library to uint256 operations 
    using SafeMath for uint256;

    //Public variables
    address public dividendWallet; 
    Proposal[] public proposals;
    uint256 public debatingPeriodInHours;
    uint256 public minimumMajorityPassing; 
    uint256 public minimumQuorumPercent;
    uint256 public numProposals;
    uint256 public numberOfRecordEntries; 
    uint256 public recordTokenSupply; 

    //Variables
    address[] recordTokenHolders;
    mapping (address => uint256) dividend;
    mapping (address => uint256) recordBalance; 
    mapping (address => uint256) recordTokenHolderID;  

    //Contract events
    event ProposalAdded(uint256 proposalID, string description);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalCounted(uint256 proposalID, int256 result, uint256 quorum, bool active);

    //Structs
    struct Proposal {
        string description;
        uint256 votingDeadline;
        mapping (address => bool) voted;
        Vote[] votes;
        uint256 currentResult;
        uint256 numberOfVotes;
        bool proposalPassed;
    }

    struct Vote {
        address voter;
        bool selection;
    }

    //Initializes the contract
    function AssetDAO(uint256 setHoursForDebate, uint256 setMajorityPercent, uint256 setQuorumPercent, 
            string tokenName, string tokenSymbol, uint256 initialAmount, address tokenSaleMultiSigWallet, 
            address orderProcessWallet, address payDividendWallet) 
        AssetTokenSale(tokenName, tokenSymbol, initialAmount, tokenSaleMultiSigWallet, orderProcessWallet) {
        debatingPeriodInHours = setHoursForDebate; 
        minimumMajorityPassing = setMajorityPercent; 
        minimumQuorumPercent = setQuorumPercent; 
        dividendWallet = payDividendWallet; 
        recordTokenHolders.length = 2;   
    }

    //Adds an address to the recorrdEntry list
    function addRecordEntry(address account) internal {
        if (recordTokenHolderID[account] == 0) {
            recordTokenHolderID[account] = recordTokenHolders.length; 
            recordTokenHolders.length++; 
            recordTokenHolders[recordTokenHolders.length.sub(1)] = account; 
            numberOfRecordEntries++;
        }
    }

    //Allocates dividend payments to token holders based on membership in DAO
    function calculateDividend() onlyOwner returns (bool success) { 
        createRecord(); 
        uint256 volume = recordTokenSupply; 
        for (uint i = 0; i < (members.length.sub(1)); i++) {
            address payee = getMember(i); 
            uint256 stake = volume.div(dividendPayment.div(multiplier));    
            uint256 dividendPayout = balanceOf(payee).div(stake).mul(multiplier); 
            dividend[payee] = 0; 
            dividend[payee] = dividend[payee].add(dividendPayout);
        }
        return true; 
    }

    //Counts the votes for a proposal
    function countVotes(uint256 proposal) onlyOwner returns (bool) {
        bool passed = false; 
        uint256 majority = numMembers.mul(minimumMajorityPassing.div(100)); 
        uint256 quorum = numMembers.mul(minimumQuorum.div(100)); 
        Proposal p = proposals[proposalNumber];
        require((p.numberOfVotes > quorum) && (now > votingDeadline));
        if (p.currentResult > majority) {
            p.executed = true;
            p.proposalPassed = true;
            passed = true; 
        } else {
            p.proposalPassed = false;
        }
        ProposalCounted(proposalNumber, p.currentResult, p.numberOfVotes, p.proposalPassed);
        return passed; 
    }

    //Allows the owner to create an record of DAO members and their balances at the time of payment
    function createRecord() internal {
        for (uint i = 0; i < (members.length.sub(1)); i++ ) {
            address holder = getMember(i);
            uint256 holderBal = balanceOf(holder); 
            addRecordEntry(holder); 
            recordBalance[holder] = holderBal; 
            recordTokenSupply = recordTokenSupply.add(holderBal); 
        }
    }

    //Returns the current dividend payment owing 
    function dividendFor(address payee) constant returns (uint256) {
        return dividend[payee];
    }

    //Returns record contents
    function getRecordBalance(address record) constant returns (uint256) {
        return recordBalance[record]; 
    }

    //Returns the address of a specific index value
    function getRecordHolder(uint256 index) constant returns (address) {
        return address(recordTokenHolders[index.add(1)]); 
    }

    //Returns the deadline of a proposal
    function getProposalDeadline(uint256 proposal) constant returns (uint256) {
        Proposal p = proposals[proposal]; 
        return p.deadline; 
    }
    
    //Returns the description of a proposal
    function getProposalDescription(uint256 proposal) constant returns (string) {
        Proposal p = proposals[proposal]; 
        return p.description; 
    }

    //Returns the status of a proposal
    function getProposalStatus(uint256 proposal) constant returns (bool success) {
        Proposal p = proposals[proposal]; 
        return p.proposalPassed; 
    }
    
    //Allows a member to propose an item for action
    function proposeItem(string proposalDescription) onlyMember returns (uint256) {
        uint256 proposalID = proposals.length++;
        Proposal p = proposals[proposalID];
        p.description = proposalDescription;
        p.votingDeadline = now.add(debatingPeriodInHours.mul(1 hours)); 
        p.numberOfVotes = 0;
        p.proposalPassed = false;
        numProposals = proposalID.add(1);
        ProposalAdded(proposalID, proposalDescription);
        return proposalID;
    }

    //Verifies the current membership of the dao
    function verifyMemberships() onlyOwner {
        checkOwnerships(); 
    }

    //Allows a member to vote on a specific proposal
    function vote(int proposal, bool supportsProposal) memberOnly returns (bool success) {
        require(checkOwnership(msg.sender) == true); 
        Proposal p = proposals[proposalNumber];         
        require(p.voted[msg.sender] == false);         
        p.voted[msg.sender] = true;                     
        p.numberOfVotes++;                              
        if (supportsProposal) {                         
            p.currentResult++;                          
        } else {                                        
            p.currentResult--;                          
        }
        Voted(proposalNumber, supportsProposal, msg.sender);
        return p.numberOfVotes;
    }
}

