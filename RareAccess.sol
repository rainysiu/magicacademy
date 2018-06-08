pragma solidity ^0.4.18;
import "./Ownable.sol";
contract RareAccess is Ownable {
  address tradeAddress;
  address platAddress;
  address raffleAddress;

  uint256 PLATPrice = 65000;

  function setPLATPrice(uint256 price) external onlyOwner {
    PLATPrice = price;
  }

  function setTradeAddress(address _address) external onlyOwner {
    require(_address != address(0));
    tradeAddress = _address;
  }

  function setPLATAddress(address _address) external onlyOwner {
    require(_address != address(0));
    platAddress = _address;
  }

  function setRaffleAddress(address _address) external onlyOwner {
    require(_address != address(0));
    raffleAddress = _address;
  }

  modifier onlyAccess() {
    require(msg.sender == tradeAddress || msg.sender == platAddress || msg.sender == raffleAddress);
    _;
  }
}