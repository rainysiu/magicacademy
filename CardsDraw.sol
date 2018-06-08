pragma solidity ^0.4.18;

interface CardsInterface {
  function setCoinBalance(address player, uint256 eth, uint8 itype, bool iflag) external;
  function setJadeCoin(address player, uint256 coin, bool iflag) external;
  function getTotalEtherPool(uint8 itype) external view returns (uint256);
  function setTotalEtherPool(uint256 inEth, uint8 itype, bool iflag) external;
  function setRoughSupply(uint256 iroughSupply) external;
}

contract CardsDraw {
  using SafeMath for SafeMath;
  //event
  event DefundDiv(uint256 sessionId, uint256 amount);

  CardsInterface public cards;

  uint256 public frozeTime;
  uint256 cooldownTime = 24 hours; 

  mapping(uint256 => uint256) DrawToSession;
  address owner;
  address autoAddress;
  uint256 session;
  function CardsDraw() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyAccess() {
    require(msg.sender == owner || msg.sender == autoAddress);
    _;
  }
  function setCardsAddress(address _address) external onlyOwner {
    cards = CardsInterface(_address);
  }

  function setAutoAddress(address _address) external onlyOwner {
    require(_address != address(0));
    autoAddress = _address;
  }



  /**cooldownTime**/
  function _triggerCooldown() internal {
    frozeTime = uint256(now + cooldownTime);
  }

  function setNextSnapshotTime(uint256 iTime) external onlyOwner {
    frozeTime = iTime;
  }
  function getNextSnapshotTime() external view returns (uint256) {
    return frozeTime;
  }

  function JadeCoinMining(address _addr, uint256 _amount) external onlyOwner {
    cards.setRoughSupply(_amount);
    cards.setJadeCoin(_addr,_amount,true);
  }

    /// @dev draw
    /// @param _itype 0 :ether, 1: plat
    /// @param _percent percent of pool
    /// @return cake of each luckies
  function beginDefundDiv(uint8 _itype, uint256 _percent, address[] _address, uint256[] _amount) external onlyAccess {
    require(frozeTime <= now); // must later than forzetime  
    uint256[] memory units = new uint256[](_address.length);
    session = SafeMath.add(session,1);
    uint256 amount = SafeMath.div(SafeMath.mul(cards.getTotalEtherPool(_itype),_percent),100);

    //transfer to luckies
    for (uint i=0;i<_address.length;i++) {
      if (address(_address[i]) != address(0)) {
        units[i] = SafeMath.div(SafeMath.mul(amount,_amount[i]),10000); 
        cards.setCoinBalance(address(_address[i]),units[i],_itype,true);
        DrawToSession[session] = SafeMath.add(DrawToSession[session],units[i]);
      }  
    }

    cards.setTotalEtherPool(DrawToSession[session],_itype,false);
    _triggerCooldown(); 
    DefundDiv(session, DrawToSession[session]);
  }

  function getDrawSession() external view returns(uint256[]) {
    uint256[] memory sessions = new uint256[](session); 
    uint counter =0;
    for (uint k=1;k<=session; k++){
      sessions[counter] =  DrawToSession[k];
      counter++;
    }

    return sessions;
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}