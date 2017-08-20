pragma solidity ^0.4.0;
contract HelloWorld {
    
    uint public balance;
    mapping (address => uint) balances;
    
    // constructor
    // runs once upon contract creation
    
    function HelloWorld() {
        balance = 1000;
    }

    function deposit(uint _value) returns(uint _newValue) {
        balance += _value;
        return balance;
    }
}