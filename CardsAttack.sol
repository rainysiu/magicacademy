pragma solidity ^0.4.18;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./GameConfigInterface.sol";
import "./CardsInterface.sol";

contract CardsAttack is Ownable {
  using SafeMath for SafeMath;

  event PlayerAttacked(address attacker, address target, bool success, uint256 gooStolen);

  mapping(address => uint256) private battleCooldown; // If user attacks they cannot attack again for short time
  mapping(address => bool) private protectedAddresses; // For npc exchanges (requires 0 goo production) 

  CardsInterface public cards;
  GameConfigInterface public schema;

  /// 外部调用函数，设置防攻击的白名单
  function protectAddress(address exchange, bool isProtected) external onlyOwner {
    if (isProtected) {
      require(cards.getJadeProduction(exchange) == 0); // Can't protect actual players
    }
    protectedAddresses[exchange] = isProtected;  //设置白名单
  }

  function setCardsAddress(address _address) external onlyOwner {
    cards = CardsInterface(_address);
  }

   //设置游戏参数
  function setConfigAddress(address _address) external onlyOwner {
    schema = GameConfigInterface(_address);
  }

  /// 攻击
  function attackPlayer(address target) external {
    require(battleCooldown[msg.sender] < block.timestamp);  //冷却时间
    require(target != msg.sender);  // 攻击的不可以是自己 
    require(!protectedAddresses[target]); //target not whitelisted (i.e. exchange wallets)  //不在保护的白名单
        
    uint256 attackingPower;
    uint256 defendingPower;
    uint256 stealingPower;
   // (attackingPower, defendingPower, stealingPower) = getPlayersBattlePower(msg.sender, target);  //获取攻击者和被攻击者的战斗力
    
    (attackingPower,,stealingPower,) = cards.getPlayersBattleStats(msg.sender);
    (,defendingPower,,) = cards.getPlayersBattleStats(target);
    if (battleCooldown[target] > block.timestamp) { // When on battle cooldown you're vulnerable (starting value is 50% normal power)
      defendingPower = schema.getWeakenedDefensePower(defendingPower);
    }
        
    if (attackingPower > defendingPower) {   // 攻击力大于防御者的防御能力
      battleCooldown[msg.sender] = SafeMath.add(block.timestamp , 30 minutes);  // 触发冷却时间-30分钟
      if (cards.balanceOf(target) > stealingPower) {  //如果目标者的余额 > 攻击者的偷窃能力
        // Save all their unclaimed goo, then steal attacker's max capacity (at same time)
        uint256 unclaimedCoin = cards.balanceOfUnclaimed(target);  //目标者的冻结的jade
        if (stealingPower > unclaimedCoin) {  // 如果偷窃能力大余 冻结的jade
          uint256 coinDecrease = SafeMath.sub(stealingPower,unclaimedCoin);  //可偷窃获得jade = 偷窃力 - 冻结
          cards.setJadeCoin(target,coinDecrease,false);  // 被攻击者的账户jade 余额减少
        } else {  
          uint256 coinGain = SafeMath.sub(unclaimedCoin,stealingPower);  // 被攻击者获得jade
          //jadeBalance[target] += coinGain;
          cards.setJadeCoin(target,coinGain,true);
        }
        cards.setJadeCoin(msg.sender,stealingPower,true);  
        PlayerAttacked(msg.sender, target, true, stealingPower);
      } else {
        PlayerAttacked(msg.sender, target, true, cards.balanceOf(target));  // 事件：战斗胜利了
        cards.setJadeCoin(msg.sender,cards.balanceOf(target),true); //从账户余额中转移jade 给攻击者
        cards.setJadeCoinZero(target); // 归0
      }
            
      cards.setLastJadeSaveTime(target);
            // We don't need to claim/save msg.sender's goo (as production delta is unchanged)
      } else {
      battleCooldown[msg.sender] = SafeMath.add(block.timestamp , 10 minutes);  // 触发战斗冷却时间-10分钟
      PlayerAttacked(msg.sender, target, false, 0);  //战斗失败了
      }
  }
}