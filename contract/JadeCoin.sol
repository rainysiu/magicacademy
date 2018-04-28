pragma solidity ^0.4.18;
import "./SafeMath.sol";
import "./JadeAccess.sol";

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
// Jade - Crypto Magic Acacedy Game
// https://www.magicAcademy.io

contract JadeCoin is ERC20, JadeAccess {
  using SafeMath for SafeMath;
  string public constant name  = "MAGICACADEMY";
  string public constant symbol = "Jade";
  uint8 public constant decimals = 0;
  uint256 public roughSupply;
  uint256 public totalJadeProduction;

  uint256 public totalEtherPool; // totalEtherJadeResearchPool Eth dividends to be split between players' goo production
  uint256[] public totalJadeProductionSnapshots; // The total goo production for each prior day past
  uint256[] public allocatedJadeResearchSnapshots; // The research eth allocated to each prior day past
  uint256 public nextSnapshotTime;

  // Balances for each player
  mapping(address => uint256) public ethBalance;
  mapping(address => uint256) public jadeBalance;
  
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

   /// 代币jade的总量
  function totalSupply() public constant returns(uint256) {
    return roughSupply; // Stored goo (rough supply as it ignores earned/unclaimed goo)
  }
  /// 某个玩家的代币余款 in-game
  function balanceOf(address player) public constant returns(uint256) {
    return SafeMath.add(jadeBalance[player],balanceOfUnclaimed(player));
  }
  ///还未入账的代币
  function balanceOfUnclaimed(address player) public constant returns (uint256) {
    uint256 icount;
    if (lastJadeSaveTime[player] > 0 && lastJadeSaveTime[player] < block.timestamp) { //上一次提取Jade的时间>0 并且小于当前时间
      icount = SafeMath.mul(getJadeProduction(player),SafeMath.div(SafeMath.sub(block.timestamp,lastJadeSaveTime[player]),60));
      return icount; //计算累计的未提取代币
    }
    return 0;
  }
  
  /// 获取玩家的物品的每秒产量
  function getJadeProduction(address player) public constant returns (uint256){
    return jadeProductionSnapshots[player][lastJadeProductionUpdate[player]];
  }

  function getlastJadeProductionUpdate(address player) public view returns (uint256) {
    return lastJadeProductionUpdate[player];
  }
    /// 提升产量 
  function increasePlayersJadeProduction(address player, uint256 increase) external onlyAccess {
    jadeProductionSnapshots[player][allocatedJadeResearchSnapshots.length] = SafeMath.add(getJadeProduction(player),increase);
    lastJadeProductionUpdate[player] = allocatedJadeResearchSnapshots.length;
    totalJadeProduction = SafeMath.add(totalJadeProduction,increase);
  }

  /// 降低产量
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

  /// 更新玩家的余额，存储到数组
  function updatePlayersCoin(address player) internal {
    uint256 coinGain = balanceOfUnclaimed(player);
    lastJadeSaveTime[player] = block.timestamp;
    roughSupply = SafeMath.add(roughSupply,coinGain);  //总产量
    jadeBalance[player] = SafeMath.add(jadeBalance[player],coinGain);  //玩家所得的代币
  }

  /// 更新玩家的余额，存储到数组
  function updatePlayersCoinByOut(address player) external onlyAccess {
    uint256 coinGain = balanceOfUnclaimed(player);
    lastJadeSaveTime[player] = block.timestamp;
    roughSupply = SafeMath.add(roughSupply,coinGain);  //总产量
    jadeBalance[player] = SafeMath.add(jadeBalance[player],coinGain);  //玩家所得的代币
  }

  /// 某个玩家的ether余款 in-game
  function etherBalanceOf(address player) external constant returns(uint256) {
    return ethBalance[player];
  }

  /// 向某个地址转账代币
  function transfer(address recipient, uint256 amount) public returns (bool) {
    updatePlayersCoin(msg.sender);
    require(amount <= jadeBalance[msg.sender]);
    jadeBalance[msg.sender] = SafeMath.sub(jadeBalance[msg.sender],amount);
    jadeBalance[msg.sender] = SafeMath.add(jadeBalance[recipient],amount);
        
    Transfer(msg.sender, recipient, amount);
    return true;
  }
  /// 发起让player向另一接受者转账
  function transferFrom(address player, address recipient, uint256 amount) public returns (bool) {
    updatePlayersCoin(player);
    require(amount <= allowed[player][msg.sender] && amount <= jadeBalance[msg.sender]);
        
    jadeBalance[player] = SafeMath.sub(jadeBalance[player],amount); //player 的钱减少
    jadeBalance[player] = SafeMath.add(jadeBalance[player],amount); //接收者钱增加
    allowed[player][msg.sender] = SafeMath.sub(allowed[player][msg.sender],amount); //被授权操作的人可操作的金额减少
        
    Transfer(player, recipient, amount);  //转账事件
    return true;
  }
  /// 授权给授权单位可操作的金额
  function approve(address approvee, uint256 amount) public returns (bool) {
    allowed[msg.sender][approvee] = amount;  // 授权可操作金额
    Approval(msg.sender, approvee, amount);
    return true;
  }
  /// 增加授权单位
  function allowance(address player, address approvee) public constant returns(uint256) {
    return allowed[player][approvee];  
  }
  
  /// 更新玩家的Jade代币余额，通过出售或者买入方式获得/减少Jade ，更新数组
  function updatePlayersCoinByPurchase(address player, uint256 purchaseCost) external onlyAccess {
    uint256 unclaimedJade = balanceOfUnclaimed(player);
        
    if (purchaseCost > unclaimedJade) {
      uint256 coinDecrease = SafeMath.sub(purchaseCost, unclaimedJade);
      roughSupply = SafeMath.sub(roughSupply,coinDecrease);
      jadeBalance[player] = SafeMath.sub(jadeBalance[player],coinDecrease);
    } else {
      uint256 coinGain = SafeMath.sub(unclaimedJade,purchaseCost);
      roughSupply = SafeMath.add(roughSupply,coinGain);
      jadeBalance[player] = SafeMath.add(jadeBalance[player],coinGain);
    }
        
    lastJadeSaveTime[player] = block.timestamp;
  }
  /// 提现，提取ether 到自己的账户
  function withdrawEther(address player, uint256 amount) external {
    require(amount <= ethBalance[player]);
    ethBalance[player] = SafeMath.sub(ethBalance[player],amount);
    player.transfer(amount);
  } 

  function JadeCoinMining(address _addr, uint256 _amount) external onlyOwner {
    roughSupply = SafeMath.add(roughSupply,_amount);
    jadeBalance[_addr] = SafeMath.add(jadeBalance[_addr],_amount);
  }

  function setRoughSupply(uint256 iroughSupply) external onlyAccess {
    roughSupply = SafeMath.add(roughSupply,iroughSupply);
  }
  function addJadeCoin(address player, uint256 coin) external onlyAccess {
    jadeBalance[player] = SafeMath.add(jadeBalance[player],coin);
  }

  function subJadeCoin(address player, uint256 coin) external onlyAccess {
    jadeBalance[player] = SafeMath.sub(jadeBalance[player],coin);
  }
  function setJadeCoinZero(address player) external onlyAccess {
    jadeBalance[player] = 0;
  }

  function addEthBalance(address player, uint256 eth) external onlyAccess {
    ethBalance[player] = SafeMath.add(ethBalance[player],eth);
  }

  function subEthBalance(address player, uint256 eth) external onlyAccess {
    ethBalance[player] = SafeMath.sub(ethBalance[player],eth);
  }


  function setLastJadeSaveTime(address player) external onlyAccess {
    lastJadeSaveTime[player] = block.timestamp;
  }

  function setNextSnapshotTime(uint256 iTime) external onlyAccess {
    nextSnapshotTime = iTime;
  }
  function getNextSnapshotTime() external view returns (uint256) {
    return nextSnapshotTime;
  }

  function addTotalEtherPool(uint256 inEth) external onlyAccess {
    totalEtherPool = SafeMath.add(totalEtherPool,inEth);
  }

  function subTotalEtherPool(uint256 inEth) external onlyAccess {
    totalEtherPool = SafeMath.sub(totalEtherPool,inEth);
  }

  function getTotalEtherPool() external view returns (uint256) {
    return totalEtherPool;
  }
}
