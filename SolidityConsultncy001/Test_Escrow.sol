pragma solidity ^0.4.11;

//Test_Escrow.sol creates a simple escrow account that manages the sale of ERC20 tokens for ETH between two parties. 

contract ERC20 {
	//Sets events and functions for ERC20 token
	event Approval(address indexed _owner, address indexed _spender, uint _value);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	
    function allowance(address _owner, address _spender) constant returns (uint remaining);
	function approve(address _spender, uint _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
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
	function isOwner(address addr) constant returns(bool success) {
		if (addr == owner) {
			return true; 
		}
		return false; 
	}

	//Allows for transfer of contract ownership
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract TokenWithMint is ERC20, Owned {
	//Public variables
	string public name; 
	string public symbol; 
	uint256 public decimals; 
    uint256 public initialSupply; 
    uint256 public price; 
	uint256 public totalSupply; 

    //Variables
    address[] priceTokenHolders; 
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) balance;
 

    //Creates modifier to prevent short address attack
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) revert();
        _;
    }

	//Constructor
	function TokenWithMint(string tokenName, string tokenSymbol, uint8 decimalUnits, uint256 initialAmount) {
		name = tokenName; 
		symbol = tokenSymbol; 
		decimals = decimalUnits;          
        initialSupply = initialAmount; 
		totalSupply = initialSupply; 
	}
	
	//Provides the remaining balance of approved tokens from function approve 
    function allowance(address _owner, address _spender) constant returns (uint256 remainingAllowance) {
      return allowed[_owner][_spender];
    }

	//Allows for a certain amount of tokens to be spent on behalf of the account owner
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

	//Returns the account balance 
    function balanceOf(address _owner) constant returns (uint256 remainingBalance) {
        return balance[_owner];
    }

    //Returns the current price of the token for the crowdsale
    function getPrice() constant returns (uint256) {
        return price;
    }

    //Sets the token price 
    function setPrice(uint256 newPriceperEther) onlyOwner returns (uint256) {
        require(newPriceperEther > 0);  
        price = newPriceperEther; 
        return price; 
    }

	//Sends tokens from sender's account
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        if (balance[msg.sender] >= _value && (balance[_to] + _value > balance[_to])) {
            balance[msg.sender] -= _value;
            balance[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { 
			return false; 
		}
    }
	
	//Transfers tokens from an approved account 
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
        if ((balance[_from] >= _value) && (allowed[_from][msg.sender] >= _value) && (balance[_to] + _value > balance[_to])) {
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

contract Escrow is Owned, TokenWithMint {
    //Public Variables 
    address public escrowWallet; 
    Transaction[] public transactions; 
    uint256 public numTransactions; 
    
    //Variables
    string tokenName = "Test"; 
    string tokenSymbol = "tst";
    uint256 initialAmount = 100; 
    uint8 decimalUnits = 0; 

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
        //string description; 
        uint256 amtEther; 
        uint256 amtToken; 
    }

    //Initializes the contract
    function Escrow(address escrowAccount) 
        TokenWithMint(tokenName, tokenSymbol, decimalUnits, initialAmount) {
        escrowWallet = escrowAccount; 
        balance[msg.sender] = balance[msg.sender] + (initialAmount); 
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
            balance[escrowWallet] = balance[escrowWallet] - t.amtToken; 
            balance[t.seller] = balance[t.seller] + t.amtToken; 
            Transfer(escrowWallet, t.seller, t.amtToken); 
        }
        return true; 
    }

    //Allows a sender to send ETH to the contract escrow wallet as fulfillment of payment
    function buyToken(uint256 transactionNum) payable {
        Transaction storage t = transactions[transactionNum]; 
        //require((t.amtEther == msg.value) && (t.abortTrans == false));
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
        balance[escrowWallet] = balance[escrowWallet] - t.amtToken; 
        balance[t.buyer] = balance[t.buyer] + t.amtToken; 
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
        //t.description = ""; 
        t.amtEther = saleETH * 1 ether; 
        t.amtToken = saleTokens; 
        numTransactions++; 
        return transactionID; 
    }

    //Allows a sender to send the token to the contract escrow wallet as fulfillment of payment
    function sellToken(uint256 transactionNum, uint256 amount) returns (bool success) {
        Transaction storage t = transactions[transactionNum]; 
        //require((t.amtToken == amount) && (t.abortTrans == false));
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

    //Allows the owner to retrieve Ether from the contract during testing
    function payoutEther() payable onlyOwner {
        escrowWallet.transfer(this.balance);
    }
}
