pragma solidity ^0.4.18;
import "./SafeMath.sol";
import "./OperAccess.sol";

interface ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
// Jade - Crypto MagicAcacedy Game
// https://www.magicAcademy.io

contract JadeCoin is ERC20, OperAccess {
  using SafeMath for SafeMath;
  string public constant name  = "MAGICACADEMY JADE";
  string public constant symbol = "Jade";
  uint8 public constant decimals = 0;
  uint256 public roughSupply;
  uint256 public totalJadeProduction;

  uint256[] public totalJadeProductionSnapshots; // The total goo production for each prior day past
  uint256[] public allocatedJadeResearchSnapshots; // The research eth allocated to each prior day past

  // Balances for each player
  mapping(address => uint256) public jadeBalance;
  mapping(address => mapping(uint8 => uint256)) public coinBalance;
  mapping(uint256 => uint256) totalEtherPool; //Total Pool
  
  mapping(address => mapping(uint256 => uint256)) private jadeProductionSnapshots; // Store player's jade production for given day (snapshot)
  mapping(address => mapping(uint256 => bool)) private jadeProductionZeroedSnapshots; // This isn't great but we need know difference between 0 production and an unused/inactive day.
    
  mapping(address => uint256) public lastJadeSaveTime; // Seconds (last time player claimed their produced jade)
  mapping(address => uint256) public lastJadeProductionUpdate; // Days (last snapshot player updated their production)
  mapping(address => uint256) private lastJadeResearchFundClaim; // Days (snapshot number)
   
  // Mapping of approved ERC20 transfers (by player)
  mapping(address => mapping(address => uint256)) private allowed;
     
  // Constructor
  function JadeCoin() public {
  }

  function totalSupply() public constant returns(uint256) {
    return roughSupply; // Stored jade (rough supply as it ignores earned/unclaimed jade)
  }
  /// balance of jade in-game
  function balanceOf(address player) public constant returns(uint256) {
    return SafeMath.add(jadeBalance[player],balanceOfUnclaimed(player));
  }
  /// unclaimed jade
  function balanceOfUnclaimed(address player) public constant returns (uint256) {
    uint256 lSave = lastJadeSaveTime[player];
    if (lSave > 0 && lSave < block.timestamp) { 
      return SafeMath.mul(getJadeProduction(player),SafeMath.div(SafeMath.sub(block.timestamp,lSave),60));
    }
    return 0;
  }

  /// production/s
  function getJadeProduction(address player) public constant returns (uint256){
    return jadeProductionSnapshots[player][lastJadeProductionUpdate[player]];
  }

  function getlastJadeProductionUpdate(address player) public view returns (uint256) {
    return lastJadeProductionUpdate[player];
  }
    /// increase prodution 
  function increasePlayersJadeProduction(address player, uint256 increase) external onlyAccess {
    jadeProductionSnapshots[player][allocatedJadeResearchSnapshots.length] = SafeMath.add(getJadeProduction(player),increase);
    lastJadeProductionUpdate[player] = allocatedJadeResearchSnapshots.length;
    totalJadeProduction = SafeMath.add(totalJadeProduction,increase);
  }

  /// reduce production
  function reducePlayersJadeProduction(address player, uint256 decrease) external onlyAccess {
    uint256 previousProduction = getJadeProduction(player);
    uint256 newProduction = SafeMath.sub(previousProduction, decrease);

    if (newProduction == 0) { 
      jadeProductionZeroedSnapshots[player][allocatedJadeResearchSnapshots.length] = true;
      delete jadeProductionSnapshots[player][allocatedJadeResearchSnapshots.length]; // 0
    } else {
      jadeProductionSnapshots[player][allocatedJadeResearchSnapshots.length] = newProduction;
    }   
    lastJadeProductionUpdate[player] = allocatedJadeResearchSnapshots.length;
    totalJadeProduction = SafeMath.sub(totalJadeProduction,decrease);
  }

  /// update player's jade balance
  function updatePlayersCoin(address player) internal {
    uint256 coinGain = balanceOfUnclaimed(player);
    lastJadeSaveTime[player] = block.timestamp;
    roughSupply = SafeMath.add(roughSupply,coinGain);  
    jadeBalance[player] = SafeMath.add(jadeBalance[player],coinGain);  
  }

  /// update player's jade balance
  function updatePlayersCoinByOut(address player) external onlyAccess {
    uint256 coinGain = balanceOfUnclaimed(player);
    lastJadeSaveTime[player] = block.timestamp;
    roughSupply = SafeMath.add(roughSupply,coinGain);  
    jadeBalance[player] = SafeMath.add(jadeBalance[player],coinGain);  
  }
  /// transfer
  function transfer(address recipient, uint256 amount) public returns (bool) {
    updatePlayersCoin(msg.sender);
    require(amount <= jadeBalance[msg.sender]);
    jadeBalance[msg.sender] = SafeMath.sub(jadeBalance[msg.sender],amount);
    jadeBalance[recipient] = SafeMath.add(jadeBalance[recipient],amount);
    Transfer(msg.sender, recipient, amount);
    return true;
  }
  /// transferfrom
  function transferFrom(address player, address recipient, uint256 amount) public returns (bool) {
    updatePlayersCoin(player);
    require(amount <= allowed[player][msg.sender] && amount <= jadeBalance[player]);
        
    jadeBalance[player] = SafeMath.sub(jadeBalance[player],amount); 
    jadeBalance[recipient] = SafeMath.add(jadeBalance[recipient],amount); 
    allowed[player][msg.sender] = SafeMath.sub(allowed[player][msg.sender],amount); 
        
    Transfer(player, recipient, amount);  
    return true;
  }
  
  function approve(address approvee, uint256 amount) public returns (bool) {
    allowed[msg.sender][approvee] = amount;  
    Approval(msg.sender, approvee, amount);
    return true;
  }
  
  function allowance(address player, address approvee) public constant returns(uint256) {
    return allowed[player][approvee];  
  }
  
  /// update Jade via purchase
  function updatePlayersCoinByPurchase(address player, uint256 purchaseCost) external onlyAccess {
    uint256 unclaimedJade = balanceOfUnclaimed(player);
        
    if (purchaseCost > unclaimedJade) {
      uint256 jadeDecrease = SafeMath.sub(purchaseCost, unclaimedJade);
      require(jadeBalance[player] >= jadeDecrease);
      roughSupply = SafeMath.sub(roughSupply,jadeDecrease);
      jadeBalance[player] = SafeMath.sub(jadeBalance[player],jadeDecrease);
    } else {
      uint256 jadeGain = SafeMath.sub(unclaimedJade,purchaseCost);
      roughSupply = SafeMath.add(roughSupply,jadeGain);
      jadeBalance[player] = SafeMath.add(jadeBalance[player],jadeGain);
    }
        
    lastJadeSaveTime[player] = block.timestamp;
  }

  function JadeCoinMining(address _addr, uint256 _amount) external onlyOwner {
    roughSupply = SafeMath.add(roughSupply,_amount);
    jadeBalance[_addr] = SafeMath.add(jadeBalance[_addr],_amount);
  }

  function setRoughSupply(uint256 iroughSupply) external onlyAccess {
    roughSupply = SafeMath.add(roughSupply,iroughSupply);
  }
  /// balance of coin  in-game
  function coinBalanceOf(address player,uint8 itype) external constant returns(uint256) {
    return coinBalance[player][itype];
  }

  function setJadeCoin(address player, uint256 coin, bool iflag) external onlyAccess {
    if (iflag) {
      jadeBalance[player] = SafeMath.add(jadeBalance[player],coin);
    } else if (!iflag) {
      jadeBalance[player] = SafeMath.sub(jadeBalance[player],coin);
    }
  }
  
  function setCoinBalance(address player, uint256 eth, uint8 itype, bool iflag) external onlyAccess {
    if (iflag) {
      coinBalance[player][itype] = SafeMath.add(coinBalance[player][itype],eth);
    } else if (!iflag) {
      coinBalance[player][itype] = SafeMath.sub(coinBalance[player][itype],eth);
    }
  }

  function setLastJadeSaveTime(address player) external onlyAccess {
    lastJadeSaveTime[player] = block.timestamp;
  }

  function setTotalEtherPool(uint256 inEth, uint8 itype, bool iflag) external onlyAccess {
    if (iflag) {
      totalEtherPool[itype] = SafeMath.add(totalEtherPool[itype],inEth);
     } else if (!iflag) {
      totalEtherPool[itype] = SafeMath.sub(totalEtherPool[itype],inEth);
    }
  }

  function getTotalEtherPool(uint8 itype) external view returns (uint256) {
    return totalEtherPool[itype];
  }

  function setJadeCoinZero(address player) external onlyAccess {
    jadeBalance[player]=0;
  }
}
