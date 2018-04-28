pragma solidity ^0.4.18;

/**有关游戏的合约，定义卡牌的参数 **/
contract GameConfig {
  using SafeMath for SafeMath;
  address public owner;

  /**event**/
  event newCard(uint256 cardId,uint256 baseCoinCost,uint256 coinCostIncreaseHalf,uint256 ethCost,uint256 baseCoinProduction,uint256 attackValue,uint256 defenseValue,uint256 coinStealingCapacity);
  event newUpgradeCard(uint256 upgradecardId, uint256 coinCost, uint256 ethCost, uint256 upgradeClass, uint256 cardId, uint256 upgradeValue, uint256 increase);
  event newRareCard(uint256 rarecardId,uint256 ethCost, uint256 rareClass, uint256 cardId, uint256 rareValue); 

  struct Card {
    uint256 cardId;
    uint256 baseCoinCost;
    uint256 coinCostIncreaseHalf; // Halfed to make maths slightly less (cancels a 2 out)
    uint256 ethCost;
    uint256 baseCoinProduction;
        
    uint256 attackValue;
    uint256 defenseValue;
    uint256 coinStealingCapacity;
    bool unitSellable; // Rare units (from raffle) not sellable
  }
    
  struct UpgradeCard {
    uint256 upgradecardId;
    uint256 coinCost;
    uint256 ethCost;
    uint256 upgradeClass;
    uint256 cardId;
    uint256 upgradeValue;
    uint256 increase;
  }
    
  struct RareCard {
    uint256 rarecardId;
    uint256 ethCost;
    uint256 rareClass;
    uint256 cardId;
    uint256 rareValue;
  }

  /** mapping**/
  mapping(uint256 => Card) private cardInfo;  //物品的映射，ID 对应 Unit 结构体
  mapping(uint256 => UpgradeCard) private upgradeInfo;  //物品的映射，ID 对应 Upgrade 结构体
  mapping(uint256 => RareCard) private rareInfo; //物品的映射，ID 对应 Rare 结构体
    
  uint256 public constant currentNumberOfUnits = 14;  //物品的种类数量
  uint256 public constant currentNumberOfUpgrades = 42; 
  uint256 public constant currentNumberOfRares = 2;
  uint8 public Max_CAP = 99;
    
  // Constructor  构造游戏的道具的基类，定义数据格式、初始化数据，及定义获取数据的方法
  function GameConfig() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function setMaxCAP(uint8 iMax) external onlyOwner {
    Max_CAP = iMax;
  }
  function getMaxCAP() external returns (uint8) {
    return Max_CAP;
  }
  function _CardConfig(uint256 _cardId, uint256 _baseCoinCost, uint256 _coinCostIncreaseHalf, uint256 _ethCost, uint256 _baseCoinProduction, uint256 _attackValue, uint256 _defenseValue, uint256 _coinStealingCapacity, bool _unitSellable) private {
    Card memory _card = Card({
      cardId: _cardId,
      baseCoinCost: _baseCoinCost,
      coinCostIncreaseHalf: _coinCostIncreaseHalf,
      ethCost: _ethCost,
      baseCoinProduction: _baseCoinProduction,
      attackValue: _attackValue,
      defenseValue: _defenseValue,
      coinStealingCapacity: _coinStealingCapacity,
      unitSellable: _unitSellable
    });
    //cards.push(_card);
    cardInfo[_cardId] = _card;
    newCard(_cardId,_baseCoinCost,_coinCostIncreaseHalf,_ethCost,_baseCoinProduction,_attackValue,_defenseValue,_coinStealingCapacity);
  } 

  function CreateCards(uint256 _cardId, uint256 _baseCoinCost, uint256 _coinCostIncreaseHalf, uint256 _ethCost, uint256 _baseCoinProduction, uint _attackValue, uint256 _defenseValue, uint256 _coinStealingCapacity, bool _unitSellable) private {
    _CardConfig(_cardId,_baseCoinCost,_coinCostIncreaseHalf,_ethCost,_baseCoinProduction,_attackValue,_defenseValue,_coinStealingCapacity, _unitSellable);
  }

  function _UpgradeCardConfig(uint256 _upgradecardId, uint256 _coinCost, uint256 _ethCost, uint256 _upgradeClass, uint256 _cardId, uint256 _upgradeValue,uint256 _increase) private {
    UpgradeCard memory _upgradecard = UpgradeCard({
      upgradecardId: _upgradecardId,
      coinCost: _coinCost,
      ethCost: _ethCost,
      upgradeClass: _upgradeClass,
      cardId: _cardId,
      upgradeValue: _upgradeValue,
      increase: _increase
    });
    //upgradecards.push(_upgradecard);
    upgradeInfo[_upgradecardId] = _upgradecard;
    newUpgradeCard(_upgradecardId,_coinCost,_ethCost,_upgradeClass,_cardId,_upgradeValue,_increase);
  } 
  function CreateUpgradeCards(uint256 _upgradecardId, uint256 _coinCost, uint256 _ethCost, uint256 _upgradeClass, uint256 _cardId, uint256 _upgradeValue, uint256 _expireDay) private {
    _UpgradeCardConfig(_upgradecardId,_coinCost,_ethCost,_upgradeClass,_cardId,_upgradeValue,_expireDay);
  }

  function _RareCardConfig(uint256 _rarecardId,uint256 _ethCost, uint256 _rareClass, uint256 _cardId, uint256 _rareValue) private {
    RareCard memory _rarecard = RareCard({
      rarecardId: _rarecardId,
      ethCost: _ethCost,
      rareClass: _rareClass,
      cardId: _cardId,
      rareValue: _rareValue
    });
    //rarecards.push(_rarecard);
    rareInfo[_rarecardId] = _rarecard;
    newRareCard(_rarecardId,_ethCost,_rareClass,_cardId,_rareValue);
  } 
  function CreateRareCards(uint256 _rarecardId,uint256 _ethCost, uint256 _rareClass, uint256 _cardId, uint256 _rareValue) private {
    _RareCardConfig(_rarecardId,_ethCost,_rareClass,_cardId,_rareValue);
  }


  /// @notice 通过物品ID获得物品的代币价值
  function getCostForCards(uint256 cardId, uint256 existing, uint256 amount) public constant returns (uint256) {
    uint256 icount = existing;
    if (amount == 1) { // 1 当总量为1
      if (existing == 0) {  //如果无该卡牌
        return cardInfo[cardId].baseCoinCost;  //当没有该ID的物品，售价为baseGooCost，否则为基础售价+上涨价*2
      } else {
        return cardInfo[cardId].baseCoinCost + (existing * cardInfo[cardId].coinCostIncreaseHalf * 2);
            }
    } else if (amount > 1) { //当总量>1
      uint256 existingCost;
      if (existing > 0) {
        existingCost = (cardInfo[cardId].baseCoinCost * existing) + (existing * (existing - 1) * cardInfo[cardId].coinCostIncreaseHalf);
      }
      icount = SafeMath.add(existing,amount);  
      uint256 newCost = SafeMath.add(SafeMath.mul(cardInfo[cardId].baseCoinCost, icount), SafeMath.mul(SafeMath.mul(icount, (icount - 1)), cardInfo[cardId].coinCostIncreaseHalf));
      return newCost - existingCost;
    }
  }

  /// @notice 通过物品ID获得物品的升级价值
  function getCostForUprade(uint256 cardId, uint256 existing, uint256 amount) public constant returns (uint256) {
    uint256 icount = existing;
    if (amount == 1) { // 1 当总量为1
      if (existing == 0) {  //如果无该卡牌
        return upgradeInfo[cardId].coinCost;  //当没有该ID的物品，售价为baseGooCost，否则为基础售价+上涨价*2
      } else {
        return upgradeInfo[cardId].coinCost + (existing * upgradeInfo[cardId].increase * 2);
      }
    } else if (amount > 1) { //当总量>1
      uint256 existingCost;
      if (existing > 0) {
        existingCost = (upgradeInfo[cardId].coinCost * existing) + (existing * (existing - 1) * upgradeInfo[cardId].increase);
      }
      icount = SafeMath.add(existing,amount);  
      uint256 newCost = SafeMath.add(SafeMath.mul(upgradeInfo[cardId].coinCost, icount), SafeMath.mul(SafeMath.mul(icount, (icount - 1)), upgradeInfo[cardId].increase));
      return newCost - existingCost;
    }
  }

  /// @notice 削弱防御值
  function getWeakenedDefensePower(uint256 defendingPower) external constant returns (uint256) {
    return SafeMath.div(defendingPower,2);
  }
 
    /// @notice 获取物品的以太值
  function unitEthCost(uint256 cardId) external constant returns (uint256) {
    return cardInfo[cardId].ethCost;
  }
    /// @notice 获取物品的Production
  function unitCoinProduction(uint256 cardId) external constant returns (uint256) {
    return cardInfo[cardId].baseCoinProduction;
  }
    /// @notice 获取物品的战斗值
  function unitAttack(uint256 cardId) external constant returns (uint256) {
    return cardInfo[cardId].attackValue;
  }
    
  /// @notice 防御值
  function unitDefense(uint256 cardId) external constant returns (uint256) {
    return cardInfo[cardId].defenseValue;
  }
    /// @notice 偷窃能力
  function unitStealingCapacity(uint256 cardId) external constant returns (uint256) {
    return cardInfo[cardId].coinStealingCapacity;
  }
    /// 稀有物品的起步价格
  function rareStartPrice(uint256 rareId) external constant returns (uint256) {
    return rareInfo[rareId].ethCost;
  }
    
  /// 可产出的物品的ID范围
  function productionCardIdRange() external constant returns (uint256, uint256) {
    return (1, 8);
  }
  /// 战斗属性的物品的ID 范围
  function battleCardIdRange() external constant returns (uint256, uint256) {
    return (40, 45);
  }
  /// 可升级的物品ID范围
  function upgradeIdRange() external constant returns (uint256, uint256) {
    return (1, 42);
  }
  /// 稀有物品的ID范围
  function rareIdRange() external constant returns (uint256, uint256) {
    return (1, 2);
  }
  function getRareLen() external constant returns (uint256) {
    return currentNumberOfRares;
  }
  //常规卡牌的详情
  function getCardsInfo(uint256 cardId) external constant returns (
    uint256 baseCoinCost,
    uint256 coinCostIncreaseHalf,
    uint256 ethCost, 
    uint256 baseCoinProduction, 
    uint256 attackValue,
    uint256 defenseValue,
    uint256 coinStealingCapacity,
    bool  unitSellable
  ) {
    baseCoinCost = cardInfo[cardId].baseCoinCost;
    coinCostIncreaseHalf = cardInfo[cardId].coinCostIncreaseHalf;
    ethCost = cardInfo[cardId].ethCost;
    baseCoinProduction = cardInfo[cardId].baseCoinProduction;
    attackValue = cardInfo[cardId].attackValue;
    defenseValue = cardInfo[cardId].defenseValue;
    coinStealingCapacity = cardInfo[cardId].coinStealingCapacity;
    unitSellable = cardInfo[cardId].unitSellable;
  }
  //常规卡牌购买的详细数值
  function getCardInfo(uint256 cardId, uint256 existing, uint256 amount) external constant returns (uint256, uint256, uint256, uint256, bool) {
    return (cardInfo[cardId].cardId, cardInfo[cardId].baseCoinProduction, getCostForCards(cardId, existing, amount), SafeMath.mul(cardInfo[cardId].ethCost, amount),cardInfo[cardId].unitSellable);
  }

  //升级属性的卡牌的详情
  function getUpgradeInfo(uint256 upgradecardId) external constant returns (
    uint256 coinCost, 
    uint256 ethCost, 
    uint256 upgradeClass, 
    uint256 cardId, 
    uint256 upgradeValue
    ) {  
    coinCost = upgradeInfo[upgradecardId].coinCost;
    ethCost = upgradeInfo[upgradecardId].ethCost;
    upgradeClass = upgradeInfo[upgradecardId].upgradeClass;
    cardId = upgradeInfo[upgradecardId].cardId;
    upgradeValue = upgradeInfo[upgradecardId].upgradeValue;
  }

    //升级属性的卡牌的详情
  function getUpgradeCardsInfo(uint256 upgradecardId, uint256 existing) external constant returns (
    uint256 coinCost, 
    uint256 ethCost, 
    uint256 upgradeClass, 
    uint256 cardId, 
    uint256 upgradeValue
    ) {  
    coinCost = getCostForUprade(upgradecardId, existing, 1);
    //ethCost = upgradeInfo[upgradecardId].ethCost * (100 + 10 * (existing + 1))/100;
    ethCost = upgradeInfo[upgradecardId].ethCost * (100 + 10 * existing)/100;
    upgradeClass = upgradeInfo[upgradecardId].upgradeClass;
    cardId = upgradeInfo[upgradecardId].cardId;
    //upgradeValue = upgradeInfo[upgradecardId].upgradeValue;
    upgradeValue = upgradeInfo[upgradecardId].upgradeValue + existing;
  }

  //稀有物品的详情
  function getRareInfo(uint256 rareId) external view returns (
    uint256 rareClass,
    uint256 cardId,
    uint256 rareValue
  ) {
    rareClass = rareInfo[rareId].rareClass;
    cardId = rareInfo[rareId].cardId;
    rareValue = rareInfo[rareId].rareValue;
  }
  
  function InitCardConfig() external onlyOwner {
    CreateCards(1, 0, 1, 0, 2, 0, 0, 0, true);             
    CreateCards(2, 100, 50, 0, 5, 0, 0, 0, true);           
    CreateCards(3, 0, 0, 0.01 ether, 100, 0, 0, 0, true);    
    CreateCards(4, 200, 100, 0, 10, 0, 0, 0, true);          
    CreateCards(5, 500, 250, 0, 20, 0, 0, 0, true);        
    CreateCards(6, 1000, 500, 0, 40, 0, 0, 0, true);       
    CreateCards(7, 0, 1000, 0.05 ether, 500, 0, 0, 0, true); 
    CreateCards(8, 1500, 750, 0, 60, 0, 0, 0, true);
    CreateCards(9, 0, 0, 0.99 ether, 5500, 0, 0, 0 ,false); 

    //attack
    CreateCards(40, 50, 25, 0, 0, 10, 10, 10000, true);        
    CreateCards(41, 100, 50, 0, 0, 1, 25, 500, true);         
    CreateCards(42, 0, 0, 0.01 ether, 0, 200, 10, 50000, true); 
    CreateCards(43, 250, 125, 0, 0, 25, 1, 15000, true);       
    CreateCards(44, 500, 250, 0, 0, 20, 40, 5000, true);    
    CreateCards(45, 0, 2500, 0.02 ether, 0, 0, 0, 100000, true);
  }  

  function InitUpgradeCard() external onlyOwner {
    CreateUpgradeCards(1 ,10000,0 ,0,1,1,300);      
    CreateUpgradeCards(2 ,0,0.1 ether,1,1,1,100);
    CreateUpgradeCards(3 ,15000,0 ,0,1	,2,150);      
    CreateUpgradeCards(4,0,0.1 ether,1,2	,1,100);
    CreateUpgradeCards(5,15000,0,0,2,1,150);
    CreateUpgradeCards(6,0,0.2 ether,1,2,2,100);
    CreateUpgradeCards(7,17500,0,0,3	,1,300);
    CreateUpgradeCards(8,0,0.5 ether,1,3,3,100);
    CreateUpgradeCards(9,20000,0,0,3,1,50);
    CreateUpgradeCards(10,0,0.1 ether,1,4,1,100);
    CreateUpgradeCards(11,15000,0,0,4	,1,100);
    CreateUpgradeCards(12,0,0.2 ether,1,4,2	,100);
    CreateUpgradeCards(13,15000,0,0,5	,1,300);
    CreateUpgradeCards(14,0,0.5 ether,1,5,3	,100);
    CreateUpgradeCards(15,17500,0,0,5	,1,50);
    CreateUpgradeCards(16,0,0.1 ether,1,6,1	,100);
    CreateUpgradeCards(17,30000,0,0,6	,1,50);
    CreateUpgradeCards(18,0,0.2 ether,1,6,2	,100);
    CreateUpgradeCards(19,20000,0,0,7	,1,50);
    CreateUpgradeCards(20,0,0.2 ether,1,7,3	,100);
    CreateUpgradeCards(21,30000,0,0,7	,2,50);
    CreateUpgradeCards(22,0,0.1 ether,1,8,1	,100);
    CreateUpgradeCards(23,30000,0,0,8	,2,50);
    CreateUpgradeCards(24,0,0.2 ether,1,8,2	,100);
    CreateUpgradeCards(25,5000,0,2,40	,5,10);
    CreateUpgradeCards(26,0,0.1 ether,4,40	,10	,100);
    CreateUpgradeCards(27,100000,0,6,40	,10	,10);
    CreateUpgradeCards(28,0,0.2 ether,3,41,10	,100);
    CreateUpgradeCards(29,50000,0,4,41	,5,10);
    CreateUpgradeCards(30,0,0.5 ether,6,41,10	,100);
    CreateUpgradeCards(31,25000,0,5,42	,5,10);
    CreateUpgradeCards(32,0,0.2 ether,6,42,10	,100);
    CreateUpgradeCards(33,200000,0,7,42	,5,10);
    CreateUpgradeCards(34,0,0.1 ether,2,43,7	,100);
    CreateUpgradeCards(35,100000,0,4,43	,5,10);
    CreateUpgradeCards(36,0,0.2 ether,5,43,10	,100);
    CreateUpgradeCards(37,0,0.1 ether,2,44,7	,100);
    CreateUpgradeCards(38,250000,0,3,44	,5,10);
    CreateUpgradeCards(39,0,0.2 ether,4,44,10	,100);
    CreateUpgradeCards(40,500000,0,6,45	,50,10);
    CreateUpgradeCards(41,0,0.5 ether,7,45,10	,100);
    CreateUpgradeCards(42,2500000,0,7,45,7,10);
  } 

  function InitRareCard() external onlyOwner {
    CreateRareCards(1, 0.5 ether, 1, 1, 30); // 30 = +300%
    CreateRareCards(2, 0.5 ether, 0, 2, 40); // +4  = 40%  
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