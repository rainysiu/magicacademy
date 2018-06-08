pragma solidity ^0.4.18;
import "./Ownable.sol";
contract JadeAccess is Ownable {
  address tradeAddress;
  address attackAddress;
  address raffleAddress;

  function setTradeAddress(address _address) external onlyOwner {
    require(_address != address(0));
    tradeAddress = _address;
  }

  function setAttackAddress(address _address) external onlyOwner {
    require(_address != address(0));
    attackAddress = _address;
  }

  function setRaffleAddress(address _address) external onlyOwner {
    require(_address != address(0));
    raffleAddress = _address;
  }

  modifier onlyAccess() {
    require(msg.sender == tradeAddress || msg.sender == attackAddress || msg.sender == raffleAddress);
    _;
  }
}