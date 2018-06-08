pragma solidity ^0.4.18;
import "./Ownable.sol";
contract OperAccess is Ownable {
  address tradeAddress;
  address platAddress;
  address attackAddress;
  address raffleAddress;
  address drawAddress;

  function setTradeAddress(address _address) external onlyOwner {
    require(_address != address(0));
    tradeAddress = _address;
  }

  function setPLATAddress(address _address) external onlyOwner {
    require(_address != address(0));
    platAddress = _address;
  }

  function setAttackAddress(address _address) external onlyOwner {
    require(_address != address(0));
    attackAddress = _address;
  }

  function setRaffleAddress(address _address) external onlyOwner {
    require(_address != address(0));
    raffleAddress = _address;
  }

  function setDrawAddress(address _address) external onlyOwner {
    require(_address != address(0));
    drawAddress = _address;
  }

  modifier onlyAccess() {
    require(msg.sender == tradeAddress || msg.sender == platAddress || msg.sender == attackAddress || msg.sender == raffleAddress || msg.sender == drawAddress);
    _;
  }
}