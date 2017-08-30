pragma solidity ^0.4.11;

/**
* TEST_AssetToken_ICO_Escrow_v1.sol creates an asset-backed token for sale, includes administrative features for redemption of tokens for
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
	
	function AssetToken(string tokenName, string tokenSymbol) {
		name = tokenName; 
		symbol = tokenSymbol; 
		decimals = 6; 
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

contract Escrow is Owned, AssetToken {
    //Applies SafeMath library to uint256 operations 
    using SafeMath for uint256;

    //Public Variables 
    address public escrowWallet; 
    Transaction[] public transactions; 
    uint256 public numTransactions; 

    //Events
    event PaymentSubmitted(address party, uint256 amount, uint256 transID); 
    event TransactionAborted(address party, uint256 transID); 
    event TransactionCompleted(uint256 transID); 
    event TransactionInitiated(address party, uint256 transID); 
    

    struct Transaction {
        address buyer; 
        address seller; 
        bool abortTrans; 
        bool buyerPaid; 
        bool sellerPaid;  
        uint256 amtEther; 
        uint256 amtToken; 
    }

    //Initializes the contract
    function Escrow()  {
        escrowWallet = msg.sender; 
    }

    //allows either the buyer or seller to abort the transaction
    function abortTransaction(uint256 transactionNum) returns (bool success) {
        Transaction storage t = transactions[transactionNum];  
        require ((msg.sender == t.buyer) || (msg.sender == t.seller));
        t.abortTrans = true; 
        if (t.buyerPaid == true) {
            t.buyer.transfer(t.amtEther); 
        }
        if (t.sellerPaid == true) {
            balance[escrowWallet] = balance[escrowWallet].sub(t.amtToken); 
            balance[t.seller] = balance[t.seller].add(t.amtToken); 
            Transfer(escrowWallet, t.seller, t.amtToken); 
        }
        return true; 
    }

    //Allows a sender to send ETH to the contract escrow wallet as fulfillment of payment
    function buyToken(uint256 transactionNum) payable {
        Transaction storage t = transactions[transactionNum]; 
        require(t.abortTrans == false); 
        if (t.amtEther == msg.value) {
            t.buyerPaid = true; 
            PaymentSubmitted(msg.sender, msg.value, transactionNum); 
            if (t.sellerPaid == true) {
                closeSale(transactionNum); 
            }
        }
    }

    function closeSale(uint256 transactionNum) internal {
        Transaction storage t = transactions[transactionNum];
        balance[escrowWallet] = balance[escrowWallet].sub(t.amtToken); 
        balance[t.buyer] = balance[t.buyer].add(t.amtToken); 
        Transfer(escrowWallet, t.buyer, t.amtToken); 
        t.seller.transfer(t.amtEther); 
        TransactionCompleted(transactionNum); 
    }

    //Creates a transaction within the escrow
    function initializeEscrow(address buyerAddr, address sellerAddr, uint256 saleETH, uint256 saleTokens) returns (uint256) {
        uint256 transactionID = transactions.length++; 
        Transaction storage t = transactions[transactionID]; 
        t.buyer = buyerAddr; 
        t.seller = sellerAddr; 
        t.abortTrans = false; 
        t.buyerPaid = false; 
        t.sellerPaid = false;  
        t.amtEther = saleETH; 
        t.amtToken = saleTokens; 
        numTransactions++; 
        return transactionID; 
    }

    //Allows a sender to send the token to the contract escrow wallet as fulfillment of payment
    function sellToken(uint256 transactionNum, uint256 amount) returns (bool success) {
        Transaction storage t = transactions[transactionNum]; 
        require(t.abortTrans == false); 
        if (t.amtToken == amount) {
            t.sellerPaid = true; 
            transfer(escrowWallet, amount); 
            PaymentSubmitted(msg.sender, amount, transactionNum); 
            if (t.buyerPaid == true) {
                closeSale(transactionNum); 
            }
        }
        return true; 
    }

    //Sets the escrow wallet for token sales
    function setEscrowWallet(address wallet) onlyOwner returns (bool success) {
        escrowWallet = wallet; 
        return true; 
    }

    //Allows the owner to retrieve Ether from the contract during testing
    function payoutEther() payable onlyOwner {
        escrowWallet.transfer(this.balance);
    }
}


contract AssetTokenSale is Authorizable, Owned, AssetToken, Escrow {
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
    uint256 multiplier = 1000000; 

    //Events
    event DestroyTokens(address indexed _from, address indexed _to, uint256 _value);
    event RedeemTokens(address indexed _from, address indexed _to, uint256 _value); 
	
	//Initializes the token
	function AssetTokenSale(string tokenName, string tokenSymbol) 
		AssetToken(tokenName, tokenSymbol) {
            multiSigWallet = msg.sender;
            redemptionWallet = msg.sender; 
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

    //Sets the variable tokenSaleFee for the redemption process
    function setRedemptionFee(uint256 newFee) onlyAuthorized returns (uint256) {
        tokenSaleFee = newFee; 
        return tokenSaleFee; 
    }

    //Set the redemption wallet for token sale processing
    function setRedemptionWallet(address wallet) onlyOwner returns (bool success) {
        redemptionWallet = wallet; 
        return true; 
    }

    //Allows owner to start the crowdsale from the time of execution until a specified stopTime
    function startSale(uint256 price, uint256 saleStart) onlyOwner returns (bool success) {    
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


