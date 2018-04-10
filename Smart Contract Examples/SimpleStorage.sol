// signifies to compiler, source code written for 0.4 & up.
pragma solidity ^0.4.0;

//initialize storageData uint var
contract SampleContract {
 uint storageData;
 
//function to set storageData
 function set(uint x) {
 storageData = x;
 }
 
//function to get/return storageData
 function get() constant returns (uint) {
 return storageData;
 }
}