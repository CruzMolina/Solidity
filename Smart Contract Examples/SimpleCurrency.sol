pragma solidity ^0.4.0;

contract Subcurrency {
    
 address public minter;
 mapping (address => uint) public coinBalances;
 
 // Light clients can react on changes efficiently thanks to events.
 event Sent(address from, address to, uint sum);
 
 // The code of this constructor is run only once the contract is created.
 function Coin() {
   minter = msg.sender;
 }
 
 // mint x amount of coins
 function mint(address receiver, uint sum) {
   if (msg.sender != minter) return;
   coinBalances[receiver] += sum;
 }
 
 // send available coins from msg.sender to receiver
 // settle accounts & broadcast event
 function send(address receiver, uint sum) {
   if (coinBalances[msg.sender] < sum) return;
   coinBalances[msg.sender] -= sum;
   coinBalances[receiver] += sum;
   Sent(msg.sender, receiver, sum);
 }
 
 // specific function to retrieve a given address' coin balance
 function getcoinBalances(address _account) returns (uint) {
   return coinBalances[_account];
}

}