pragma solidity ^0.4.18;
import "./CardsHelper.sol";

/// @notice 购买卡牌
/// @author rainysiu 
contract CardsTrade is CardsHelper {
  function CardsTrade() public {
  }
   // Minor game events
  event UnitBought(address player, uint256 unitId, uint256 amount);
  event UpgradeCardBought(address player, uint256 upgradeId);
  event BuyRareCard(address player, address previous, uint256 rareId,uint256 iPrice);
  event UnitSold(address player, uint256 unitId, uint256 amount);
  function() external payable {
    cards.addTotalEtherPool(msg.value);
  }

  /// @notice 邀请成功赠送卡牌
  function sendGiftCard(address _address) external onlyAuto {
    uint256 existing = cards.getOwnedCount(_address,1);
    require(existing < schema.getMaxCAP());
    uint256 addAmount = SafeMath.add(existing, 1);
    require(addAmount <= schema.getMaxCAP());

    // Update players jade 修改时间戳
    cards.updatePlayersCoinByPurchase(_address, 0);
        
    if (schema.unitCoinProduction(1) > 0) {
      cards.increasePlayersJadeProduction(_address,cards.getUnitsProduction(_address, 1, 1)); //提升产量
      cards.setUintCoinProduction(msg.sender,1,cards.getUnitsProduction(msg.sender, 1, 1),"add"); 
    }
    //增加玩家数组
    if (cards.getUintsOwnerCount(_address) <= 0) {
      cards.AddPlayers(_address);
    }
    cards.setUintsOwnerCount(_address,1,"add");
  
    cards.setOwnedCount(_address,1,1,"add");
    UnitBought(_address, 1, 1);
  } 
  
  /// 用代币购买基础卡牌，在系统账户里减少代币总量
  function buyBasicCards(uint256 unitId, uint256 amount) external {
    require(cards.getGameStarted());
    require(amount>=1);
    uint256 existing = cards.getOwnedCount(msg.sender,unitId);
    uint256 iAmount;
    require(existing < schema.getMaxCAP());
    if (SafeMath.add(existing, amount) > schema.getMaxCAP()) {
      iAmount = SafeMath.sub(schema.getMaxCAP(),existing);
    } else {
      iAmount = amount;
    }
    uint256 schemaUnitId;
    uint256 coinProduction;
    uint256 coinCost;
    uint256 ethCost;
    (schemaUnitId, coinProduction, coinCost, ethCost,) = schema.getCardInfo(unitId, existing, iAmount);
   
    require(schemaUnitId>=1);
    require(cards.balanceOf(msg.sender) >= coinCost);
    require(ethCost == 0); // Free ether unit
        
    // Update players jade 修改时间戳
    cards.updatePlayersCoinByPurchase(msg.sender, coinCost);
    ///****提升产量***/
    if (coinProduction > 0) {
      cards.increasePlayersJadeProduction(msg.sender,cards.getUnitsProduction(msg.sender, unitId, iAmount)); //提升产量
      cards.setUintCoinProduction(msg.sender,unitId,cards.getUnitsProduction(msg.sender, unitId, iAmount),"add"); 
    }
    //增加玩家
    if (cards.getUintsOwnerCount(msg.sender) <=0) {
      cards.AddPlayers(msg.sender);
    }
    cards.setUintsOwnerCount(msg.sender,iAmount,"add");
    
    cards.setOwnedCount(msg.sender,unitId,iAmount,"add");
    UnitBought(msg.sender, unitId, iAmount);
  }

  /// 用ether购买卡牌，调用MateMask
  function buyEthCards(uint256 unitId, uint256 amount) external payable {
    require(cards.getGameStarted());
    require(amount>=1);
    uint256 existing = cards.getOwnedCount(msg.sender,unitId);
    require(existing < schema.getMaxCAP());    
    
    uint256 iAmount;
    if (SafeMath.add(existing, amount) > schema.getMaxCAP()) {
      iAmount = SafeMath.sub(schema.getMaxCAP(),existing);
    } else {
      iAmount = amount;
    }
    uint256 schemaUnitId;
    uint256 coinProduction;
    uint256 coinCost;
    uint256 ethCost;
    (schemaUnitId, coinProduction, coinCost, ethCost,) = schema.getCardInfo(unitId, existing, iAmount);
    require(schemaUnitId>=1);
    
    // 同时，如果该物品具有以太的标价，则用户的以太账户余额+用户从MateMask 钱包出价的前要大于标价
    require(SafeMath.add(cards.etherBalanceOf(msg.sender),msg.value) >= ethCost);
    require(cards.balanceOf(msg.sender) >= coinCost);  //账户的jade 余额 要大于 物品的jade 价格 

    // Update players jade  修改时间戳
    cards.updatePlayersCoinByPurchase(msg.sender, coinCost);

    if (ethCost > msg.value) {
      cards.subEthBalance(msg.sender,SafeMath.sub(ethCost,msg.value));
    } else if (msg.value > ethCost) {
      // Store overbid in their balance
      cards.addEthBalance(msg.sender,SafeMath.sub(msg.value,ethCost));
    } 

    uint256 devFund = uint256(SafeMath.div(SafeMath.mul(ethCost, 2), 100)); // 2% 抽成
    cards.addTotalEtherPool(uint256(SafeMath.div(SafeMath.mul(SafeMath.sub(ethCost,devFund),25),100)));  // 25% 回到池子更新奖金池
    cards.addEthBalance(owner,devFund);  //增加开发者佣金余额 ,地址改为 CardsBase 数据合约地址
  
    //该物品是否对产量有影响   
    if (coinProduction > 0) {
      cards.increasePlayersJadeProduction(msg.sender, cards.getUnitsProduction(msg.sender, unitId, iAmount)); // 获取物品的每秒产值，提升产值
      cards.setUintCoinProduction(msg.sender,unitId,cards.getUnitsProduction(msg.sender, unitId, iAmount),"add"); 
    }
    //增加玩家
    if (cards.getUintsOwnerCount(msg.sender)<=0) {
      cards.AddPlayers(msg.sender);
    }
    cards.setUintsOwnerCount(msg.sender,iAmount,"add");
    //物品总数增加
    cards.setOwnedCount(msg.sender,unitId,iAmount,"add");
    UnitBought(msg.sender, unitId, iAmount);
  }

   /// 购买具备升级属性的卡牌，用ether/Jade购买-- MateMask
  function buyUpgradeCard(uint256 upgradeId) external payable {
    require(cards.getGameStarted());
    uint256 existing = cards.getUpgradesOwned(msg.sender,upgradeId);
    require(existing<=5);  // 只能买6次
    uint256 coinCost;
    uint256 ethCost;
    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    (coinCost, ethCost, upgradeClass, unitId, upgradeValue) = schema.getUpgradeCardsInfo(upgradeId,existing);

    if (ethCost > 0) {
      require(SafeMath.add(cards.etherBalanceOf(msg.sender),msg.value) >= ethCost); //可以用系统的以太账户余额 补差价购买

      if (ethCost > msg.value) { // They can use their balance instead
        cards.subEthBalance(msg.sender, SafeMath.sub(ethCost,msg.value));
      } else if (ethCost < msg.value) {  //钱付出多了
        cards.addEthBalance(msg.sender,SafeMath.sub(msg.value,ethCost));
      } 

      // 抽成2%，不可出售升级属性的卡牌，
      uint256 devFund = uint256(SafeMath.div(SafeMath.mul(ethCost, 2), 100)); // 2% 抽成; // 2% fee on purchases (marketing, gameplay & maintenance)
      cards.addTotalEtherPool(SafeMath.sub(ethCost,devFund));
      cards.addEthBalance(owner,devFund);  //增加开发者佣金余额 数据合约地址
    }
        
     // Update 如果卡牌需要扣除代币 //修改时间戳
    require(cards.balanceOf(msg.sender) >= coinCost);  
    cards.updatePlayersCoinByPurchase(msg.sender, coinCost);
    //修改加权
    upgradeUnitMultipliers(msg.sender, upgradeClass, unitId, upgradeValue);  //卡牌加权
    cards.setUpgradesOwned(msg.sender,upgradeId); //升级卡牌升级 ，记录的是等级

     //增加玩家
    if (cards.getUintsOwnerCount(msg.sender)<=0) {
      cards.AddPlayers(msg.sender);
    }

    if (cards.getUpgradesOwned(msg.sender,upgradeId)<=0){  //如果升级卡牌已经购买过，则不增加总数
      cards.setUpgradesOwned(msg.sender,1);
    }

    UpgradeCardBought(msg.sender, upgradeId);

  }

  /// 购买稀有物品 - MateMask
  function buyRareItem(uint256 rareId) external payable {
    require(cards.getGameStarted());        
    address previousOwner = cards.getRareItemsOwner(rareId);  //当前的主人，且当前主人存在
    require(previousOwner != 0);
    require(msg.sender!=previousOwner);  // 不可以自己向自己购买
    
    uint256 ethCost = cards.getRareItemsPrice(rareId);
    uint256 totalCost = SafeMath.add(cards.etherBalanceOf(msg.sender),msg.value);
    require(totalCost >= ethCost); //判断账户余额+出价 是否大于等于物品售价
        
    // We have to claim buyer/sellder's goo before updating their production values 在调用时先更新玩家的代币
    cards.updatePlayersCoinByOut(msg.sender);
    cards.updatePlayersCoinByOut(previousOwner);

    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    (upgradeClass, unitId, upgradeValue) = schema.getRareInfo(rareId);
    
    //修改 产量、攻击加权
    upgradeUnitMultipliers(msg.sender, upgradeClass, unitId, upgradeValue); //属性加权
    removeUnitMultipliers(previousOwner, upgradeClass, unitId, upgradeValue); //降低前主人的加权值

    // Splitbid/Overbid
    if (ethCost > msg.value) {
      cards.subEthBalance(msg.sender,SafeMath.sub(ethCost,msg.value));
    } else if (msg.value > ethCost) {
      // Store overbid in their balance
      cards.addEthBalance(msg.sender,SafeMath.sub(msg.value,ethCost));
    }  
    // Distribute ethCost
    uint256 devFund = uint256(SafeMath.div(SafeMath.mul(ethCost, 2), 100)); // 2% fee on purchases (marketing, gameplay & maintenance)  抽成2%
    uint256 dividends = uint256(SafeMath.div(ethCost,20)); // 5% goes to pool 其余给卖家

    cards.addTotalEtherPool(dividends);
    cards.addEthBalance(owner,devFund);  //增加开发者佣金余额  数据合约地址
        
    // Transfer / update rare item
    cards.setRareOwner(rareId, msg.sender); // 变更物品的拥有者
    cards.setRarePrice(rareId,SafeMath.div(SafeMath.mul(ethCost,5),4));
    //前主人收到钱
    cards.addEthBalance(previousOwner,SafeMath.sub(ethCost,SafeMath.add(dividends,devFund)));
    //增加玩家
    if (cards.getUintsOwnerCount(msg.sender)<=0) {
      cards.AddPlayers(msg.sender);
    }
   
    cards.setUintsOwnerCount(msg.sender,1,"add");
    cards.setUintsOwnerCount(previousOwner,1,"sub");

    //tell the world
    BuyRareCard(msg.sender, previousOwner, rareId, ethCost);
  }
  
  /// 卖出卡牌1（产量相关）因为和加权相关的不可以出售，所以不涉及加权除权332222
  function sellCards(uint256 unitId, uint256 amount) external {
    require(cards.getGameStarted());
    uint256 existing = cards.getOwnedCount(msg.sender,unitId);
    require(existing >= amount && amount>0); //玩家出售的物品数量大于等于库存量
    existing = SafeMath.sub(existing,amount);
    uint256 coinChange;
    uint256 decreaseCoin;
    uint256 schemaUnitId;
    uint256 coinProduction;
    uint256 coinCost;
    uint256 ethCost;
    bool sellable;
    (schemaUnitId, coinProduction, coinCost, ethCost, sellable) = schema.getCardInfo(unitId, existing, amount);
    require(sellable);
    if (coinCost>0) {
      coinChange = SafeMath.add(cards.balanceOfUnclaimed(msg.sender), SafeMath.div(SafeMath.mul(coinCost,3),4)); // Claim unsaved goo whilst here
    } else {
      coinChange = cards.balanceOfUnclaimed(msg.sender); //若原值为0
    }

    cards.setLastJadeSaveTime(msg.sender); //更新个人钱包的最晚更新时间
    cards.setRoughSupply(coinChange);  
    cards.addJadeCoin(msg.sender, coinChange); // 个人账户的代币增加  25% 的原代币价值被销毁

    
    if (amount == existing) {
      decreaseCoin = cards.getUintCoinProduction(msg.sender,unitId); 
    } else {
      decreaseCoin = cards.getUnitsInProduction(msg.sender, unitId, amount);
    }
    
    if (coinProduction > 0) { //modified by rainy
      cards.reducePlayersJadeProduction(msg.sender, decreaseCoin);
      //减少单位卡牌的产值
      cards.setUintCoinProduction(msg.sender,unitId,decreaseCoin,"sub"); 
    }

    if (ethCost > 0) { // Premium units sell for 75% of buy cost
      cards.addEthBalance(msg.sender,SafeMath.div(SafeMath.mul(ethCost,3),4));
    }

    cards.setOwnedCount(msg.sender,unitId,amount,"sub"); //减去出售的量
    cards.setUintsOwnerCount(msg.sender,amount,"sub");

    //tell the world
    UnitSold(msg.sender, unitId, amount);
  }
  // 按数量提取ether
  function withdrawAmount (uint256 _amount) public onlyOwner {
    owner.transfer(_amount);
  }
   /// 提现，提取ether 到自己的账户
  function withdrawEtherFromTrade(uint256 amount) external {
    require(amount <= cards.etherBalanceOf(msg.sender));
    cards.subEthBalance(msg.sender,amount);
    msg.sender.transfer(amount);
  } 

}