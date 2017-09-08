pragma solidity ^0.4.13;

/**
* @author Tony
* Demo_ICO_Test.sol creates the client's token for crowdsale with customized features
*   Crowdsale contracts edited from original contract code at https://www.ethereum.org/crowdsale#crowdfund-your-idea
*   Additional crowdsale contracts, functions, libraries from OpenZeppelin
*       at https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts/token
*   Token contract edited from original contract code at https://www.ethereum.org/token
*   ERC20 interface and certain token functions adapted from https://github.com/ConsenSys/Tokens
**/

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


contract Token is ERC20, Owned {
    //Applies SafeMath library to uint256 operations 
    using SafeMath for uint256;

	//Public variables
	string public name; 
	string public symbol; 
	uint256 public decimals;
    uint256 public initialSupply;   
	uint256 public totalSupply; 
	
	//Creates arrays for balances
    mapping (address => uint256) balance;
    mapping (address => mapping (address => uint256)) allowed;

    //Creates modifier to prevent short address attack
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) revert();
        _;
    }

	//Constructor
	function Token(string tokenName, string tokenSymbol, uint8 decimalUnits, uint256 initialAmount) {
		name = tokenName; 
		symbol = tokenSymbol; 
		decimals = decimalUnits;   
        initialSupply = initialAmount; 
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
    function balanceOf(address _owner) constant returns (uint256 remainingBalance) {
        return balance[_owner];
    }

	//Sends tokens from sender's account
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        if ((balance[msg.sender] >= _value) && (balance[_to].add(_value) > balance[_to])) {
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


contract TokenICO is Owned, Token {
    //Applies SafeMath library to uint256 operations 
    using SafeMath for uint256;

    //Public Variables
    address public multiSigWallet;                  
    uint256 public amountRaised; 
    uint256 public bonusPercent; 
    uint256 public bonusPeriod; 
    uint256 public bonusThreshold; 
    uint256 public hardcap; 
    uint256 public minimumInvestment; 
    uint256 public numberOfArchiveEntries; 
    uint256 public numberOfTokenHolders;  
    uint256 public price;   
    uint256 public release1Date; 
    uint256 public release2Date; 
    uint256 public reservedTokens1; 
    uint256 public reservedTokens2;
    uint256 public startTime; 
    uint256 public stopTime;                     

    //Variables
    address[] archiveTokenHolders; 
    address[] tokenHolders; 
    bool crowdsaleClosed = true;     
    mapping (address => uint256) archiveBalance; 
    mapping (address => uint256) archiveTokenHolderID; 
    mapping (address => uint256) tokenHolderID;                
    string tokenName = "Demo"; 
    string tokenSymbol = "DMO"; 
    uint256 initialTokens; 
    uint256 multiplier = 1000000; 
    uint256 reserveTokens;
    uint8 decimalUnits = 6;  

    

   	//Initializes the token
	function TokenICO(address beneficiaryAccount) 
    	Token(tokenName, tokenSymbol, decimalUnits, initialTokens) {   
            multiSigWallet = beneficiaryAccount;         
            setBonusPercent(20); 
            setBonusThreshold(100); 
            setHardcap(100000000);
            setMinimumInvestment(1); 
            setPrice(1000); 
            setReserveTokens(51000000); 
            archiveTokenHolders.length = 2; 
            tokenHolders.length = 2; 
            startSale(); 
            uint256 minsLong = 30; 
            bonusPeriod = now.add(minsLong.mul(1 minutes));
            release1Date = now + 1 * 1 hours; 
            release2Date = now + 2 * 2 hours; 
            reservedTokens1 = multiplier.mul(35000000); 
            reservedTokens2 = multiplier.mul(16000000); 
    }

    //Failsafe to retrieve Ether during testing
    function payout() payable onlyOwner {
        multiSigWallet.transfer(this.balance); 
    }

    //Fallback function creates tokens and sends to investor when crowdsale is open
    function () payable {
        uint256 saleHardcap = hardcap.sub(reserveTokens); //Tony
        require((!crowdsaleClosed) 
            && (now < stopTime)
            && (msg.value >= minimumInvestment) 
            && (totalSupply.add(msg.value.mul(getPrice().mul(multiplier).div(1 ether))) <= saleHardcap)); 
        address recipient = msg.sender; 
        if (tokenHolderID[recipient] == 0) {
            addTokenHolder(recipient); 
        }
        amountRaised = amountRaised.add(msg.value); 
        uint256 tokens = msg.value.mul(getPrice().mul(multiplier)).div(1 ether);
        tokens = tokens.add(calculateBonus(tokens, msg.value)); 
        totalSupply = totalSupply.add(tokens);
        balance[recipient] = balance[recipient].add(tokens);
        //require(multiSigWallet.send(msg.value)); 
        Transfer(0, recipient, tokens);
    }
    
    //Adds an address to the archiveEntry list
    function addArchiveEntry(address account) internal {
        if (archiveTokenHolderID[account] == 0) {
            archiveTokenHolderID[account] = archiveTokenHolders.length; 
            archiveTokenHolders.length++; 
            archiveTokenHolders[archiveTokenHolders.length.sub(1)] = account; 
            numberOfArchiveEntries++;
        }
    }

    //Adds an address to the tokenHolders list 
    function addTokenHolder(address account) internal {
        if (tokenHolderID[account] == 0) {
            tokenHolderID[account] = tokenHolders.length;
            tokenHolders.length++;
            tokenHolders[tokenHolders.length.sub(1)] = account; 
            numberOfTokenHolders++;
        }
    } 

    //Calculates bonus token amount for exceeding investment threshold or occuring within bonus period
    function calculateBonus(uint256 issue, uint256 amtEther) internal returns (uint256) {
        uint256 result = 0; 
        uint256 numTokens = 0; 
        if (amtEther >= bonusThreshold) {
            uint256 bonus = issue.mul(bonusPercent).div(100); 
            numTokens = bonus;  
        }
        if (now < bonusPeriod) {
            uint256 bonus2 = issue.mul(bonusPercent).div(100); 
            numTokens = numTokens.add(bonus2); 
        }
        if (totalSupply.add(numTokens) <= hardcap) {
            result = numTokens;
        } 
        return result; 
    }

    //Allows the owner to process payout of sale proceeds 
    function closeSale() payable onlyOwner {
        require(now > stopTime); 
        if (totalSupply < hardcap) {
            uint256 difference = hardcap.sub(totalSupply); 
            totalSupply = totalSupply.add(difference); 
            balance[multiSigWallet] = balance[multiSigWallet].add(difference); 
            Transfer(0, multiSigWallet, difference); 
        }
        require(multiSigWallet.send(this.balance)); 
    }

    //Allows the owner to create an archive of token owners and their balances
    function createArchive() onlyOwner returns (bool success) {
        for (uint i = 0; (i < (tokenHolders.length.sub(1))); i++ ) {
            address holder = getTokenHolder(i);
            uint256 holderBal = balanceOf(holder); 
            addArchiveEntry(holder); 
            archiveBalance[holder] = holderBal; 
        }
        return true; 
    }

    //Returns archive contents
    function getArchivedBalance(address archive) constant returns (uint archivedBalance) {
        return archiveBalance[archive]; 
    }

    //Returns the address of a specific index value
    function getArchivedHolder(uint256 index) constant returns (address archivedTokenHolder) {
        return address(archiveTokenHolders[index.add(1)]); 
    }
    
    //Returns the current price of the token for the crowdsale
    function getPrice() returns (uint256 result) {
        return price;
    }

    //Returns the address of a specific index value
	function getTokenHolder(uint256 index) internal returns (address) {
		return address(tokenHolders[index.add(1)]);
	}

    //Allows the owner to release 35,000,000 reserved tokens after 6 months
    function releaseReservedTokens1() onlyOwner returns (bool success) {
        if (now < release1Date) revert(); 
        balance[multiSigWallet] = balance[multiSigWallet].add(reservedTokens1);
        Transfer(0, multiSigWallet, reservedTokens1);
        return true; 
    }

    //Allows the owner to release 23,000,000 reserved tokens after 2 years
    function releaseReservedTokens2() onlyOwner returns (bool success) {
        if (now < release2Date) revert(); 
        balance[multiSigWallet] = balance[multiSigWallet].add(reservedTokens2);
        Transfer(0, multiSigWallet, reservedTokens2);
        return true; 
    }

    //Allows the owner to set the bonus amount expressed in a percentage
    function setBonusPercent(uint256 percent) onlyOwner returns (uint256) {
        bonusPercent = percent; 
        return bonusPercent; 
    }

    //Allows the owner to the bonus period of the crowdsale
    function setBonusPeriod(uint256 newBonusPeriod) onlyOwner returns (uint256) {
        bonusPeriod = newBonusPeriod.mul(1 hours); 
        return bonusPeriod; 
    }

    //Allows the owner to set the bonus amount invested that triggers a bonus payment
    function setBonusThreshold(uint256 investment) onlyOwner returns (uint256) {
        uint256 formatAmount = investment.mul(1 ether); 
        bonusThreshold = formatAmount; 
        return bonusThreshold; 
    }

    //Allows the owner to change the hardcap value
    function setHardcap(uint256 newHardcap) onlyOwner returns (uint256) {
        hardcap = newHardcap.mul(multiplier); 
        return hardcap; 
    }

    //Sets the minimum investment amount in Ether
    function setMinimumInvestment(uint256 investment) onlyOwner returns (uint256) {
        uint256 formatAmount = investment.mul(1 ether); 
        minimumInvestment = formatAmount; 
        return minimumInvestment; 
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

    //Sets the reserve token amount
    function setReserveTokens(uint256 amount) internal {
        uint256 formatVolume = amount.mul(multiplier); 
        reserveTokens = formatVolume; 
        initialSupply = initialSupply.add(reserveTokens); 
        totalSupply = totalSupply.add(reserveTokens); 
    }

    //Allows owner to start the crowdsale from the time of execution until a specified stopTime
    function startSale(/*uint256 saleStart, uint256 saleStop, uint256 bonusPeriodLasts, uint256 saleLimit*/) onlyOwner returns (bool success) {
        //require(saleStop > now);  
        //startTime = saleStart; 
        //stopTime = saleStop;    
        //setBonusPeriod(bonusPeriodLasts); 
        //setHardcap(saleLimit); 
        startTime = now; 
        stopTime = now.add(1 hours); 
        //release1Date = stopTime.add((6).mul(1 months)); 
        //release2Date = stopTime.add((2).mul(1 years)); 
        crowdsaleClosed = false; 
        return true; 
    }

    //Allows owner to stop the crowdsale immediately
    function stopSale() onlyOwner returns (bool success) {
        stopTime = now; 
        crowdsaleClosed = true;
        return true; 
    }
}


