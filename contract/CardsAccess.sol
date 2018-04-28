pragma solidity ^0.4.18;

contract CardsAccess {
  address autoAddress;
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function CardsAccess() public {
    owner = msg.sender;
  }

  function setAutoAddress(address _address) external onlyOwner {
    require(_address != address(0));
    autoAddress = _address;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyAuto() {
    require(msg.sender == autoAddress);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}