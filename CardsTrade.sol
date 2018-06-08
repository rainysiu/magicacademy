pragma solidity ^0.4.18;
import "./CardsHelper.sol";

/// @notice Purchase via Ether
/// @author rainysiu rainy@livestar.com
contract CardsTrade is CardsHelper {
   // Minor game events
  event UnitBought(address player, uint256 unitId, uint256 amount);
  event UpgradeCardBought(address player, uint256 upgradeId);
  event BuyRareCard(address player, address previous, uint256 rareId,uint256 iPrice);
  event UnitSold(address player, uint256 unitId, uint256 amount);

  mapping(address => mapping(uint256 => uint256)) unitsOwnedOfEth; //cards bought through ether

  function() external payable {
    cards.setTotalEtherPool(msg.value,0,true);
  }
  
  /// @notice invite 
  function sendGiftCard(address _address) external onlyAuto {
    uint256 existing = cards.getOwnedCount(_address,1);
    require(existing < schema.getMaxCAP());
    require(SafeMath.add(existing,1) <= schema.getMaxCAP());

    // Update players jade
    cards.updatePlayersCoinByPurchase(_address, 0);
        
    if (schema.unitCoinProduction(1) > 0) {
      cards.increasePlayersJadeProduction(_address,cards.getUnitsProduction(_address, 1, 1)); 
      cards.setUintCoinProduction(_address,1,cards.getUnitsProduction(_address, 1, 1),true); 
    }
    //players
    if (cards.getUintsOwnerCount(_address) <= 0) {
      cards.AddPlayers(_address);
    }
    cards.setUintsOwnerCount(_address,1,true);
  
    cards.setOwnedCount(_address,1,1,true);
    UnitBought(_address, 1, 1);
  } 
  
  /// buy normal cards with jade
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
    uint256 coinProduction;
    uint256 coinCost;
    uint256 ethCost;
    if (unitId>=1 && unitId<=39) {    
      (, coinProduction, coinCost, ethCost,) = schema.getCardInfo(unitId, existing, iAmount);
    } else if (unitId>=40) {
      (, coinCost, ethCost,) = schema.getBattleCardInfo(unitId, existing, iAmount);
    }
    require(cards.balanceOf(msg.sender) >= coinCost);
    require(ethCost == 0); // Free ether unit
        
    // Update players jade 
    cards.updatePlayersCoinByPurchase(msg.sender, coinCost);
    ///****increase production***/
    if (coinProduction > 0) {
      cards.increasePlayersJadeProduction(msg.sender,cards.getUnitsProduction(msg.sender, unitId, iAmount)); 
      cards.setUintCoinProduction(msg.sender,unitId,cards.getUnitsProduction(msg.sender, unitId, iAmount),true); 
    }
    //players
    if (cards.getUintsOwnerCount(msg.sender)<=0) {
      cards.AddPlayers(msg.sender);
    }
    cards.setUintsOwnerCount(msg.sender,iAmount,true);
    cards.setOwnedCount(msg.sender,unitId,iAmount,true);
    
    UnitBought(msg.sender, unitId, iAmount);
  }

  /// buy cards with ether
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
    uint256 coinProduction;
    uint256 coinCost;
    uint256 ethCost;
    if (unitId>=1 && unitId<=39) {
      (,coinProduction, coinCost, ethCost,) = schema.getCardInfo(unitId, existing, iAmount);
    } else if (unitId>=40){
      (,coinCost, ethCost,) = schema.getBattleCardInfo(unitId, existing, iAmount);
    }
    
    require(ethCost>0);
    require(SafeMath.add(cards.coinBalanceOf(msg.sender,0),msg.value) >= ethCost);
    require(cards.balanceOf(msg.sender) >= coinCost);  

    // Update players jade  
    cards.updatePlayersCoinByPurchase(msg.sender, coinCost);

    if (ethCost > msg.value) {
      cards.setCoinBalance(msg.sender,SafeMath.sub(ethCost,msg.value),0,false);
    } else if (msg.value > ethCost) {
      // Store overbid in their balance
      cards.setCoinBalance(msg.sender,SafeMath.sub(msg.value,ethCost),0,true);
    } 

    uint256 devFund = uint256(SafeMath.div(ethCost,20)); // 5% defund
    cards.setTotalEtherPool(uint256(SafeMath.div(ethCost,4)),0,true);  // 25% go to pool
    cards.setCoinBalance(owner,devFund,0,true);  
  
    //check procution   
    if (coinProduction > 0) {
      cards.increasePlayersJadeProduction(msg.sender, cards.getUnitsProduction(msg.sender, unitId, iAmount)); // increase procuction
      cards.setUintCoinProduction(msg.sender,unitId,cards.getUnitsProduction(msg.sender, unitId, iAmount),true); 
    }
    //players
    if (cards.getUintsOwnerCount(msg.sender)<=0) {
      cards.AddPlayers(msg.sender);
    }
    cards.setUintsOwnerCount(msg.sender,iAmount,true);
    cards.setOwnedCount(msg.sender,unitId,iAmount,true);
    unitsOwnedOfEth[msg.sender][unitId] = SafeMath.add(unitsOwnedOfEth[msg.sender][unitId],iAmount);
    UnitBought(msg.sender, unitId, iAmount);
  }

   /// buy upgrade cards with ether/Jade
  function buyUpgradeCard(uint256 upgradeId) external payable {
    require(cards.getGameStarted());
    require(upgradeId>=1);
    uint256 existing = cards.getUpgradesOwned(msg.sender,upgradeId);
    require(existing<=5); 
    uint256 coinCost;
    uint256 ethCost;
    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    (coinCost, ethCost, upgradeClass, unitId, upgradeValue,) = schema.getUpgradeCardsInfo(upgradeId,existing);

    if (ethCost > 0) {
      require(SafeMath.add(cards.coinBalanceOf(msg.sender,0),msg.value) >= ethCost); 
      
      if (ethCost > msg.value) { // They can use their balance instead
        cards.setCoinBalance(msg.sender, SafeMath.sub(ethCost,msg.value),0,false);
      } else if (ethCost < msg.value) {  
        cards.setCoinBalance(msg.sender,SafeMath.sub(msg.value,ethCost),0,true);
      } 

      // defund 5%
      uint256 devFund = uint256(SafeMath.div(ethCost, 20)); // 5% fee on purchases (marketing, gameplay & maintenance)
      cards.setTotalEtherPool(SafeMath.sub(ethCost,devFund),0,true); // go to pool 95%
      cards.setCoinBalance(owner,devFund,0,true);  
    }
    require(cards.balanceOf(msg.sender) >= coinCost);  
    cards.updatePlayersCoinByPurchase(msg.sender, coinCost);

    upgradeUnitMultipliers(msg.sender, upgradeClass, unitId, upgradeValue);  
    cards.setUpgradesOwned(msg.sender,upgradeId); //upgrade cards level

    UpgradeCardBought(msg.sender, upgradeId);
  }

  // Allows someone to send ether and obtain the token
  function buyRareItem(uint256 rareId) external payable {
    require(cards.getGameStarted());        
    address previousOwner = rare.getRareItemsOwner(rareId); 
    require(previousOwner != 0);
    require(msg.sender!=previousOwner);  // can not buy from itself
    
    uint256 ethCost = rare.getRareItemsPrice(rareId);
    uint256 totalCost = SafeMath.add(cards.coinBalanceOf(msg.sender,0),msg.value);
    require(totalCost >= ethCost); 
        
    // We have to claim buyer/sellder's goo before updating their production values 
    cards.updatePlayersCoinByOut(msg.sender);
    cards.updatePlayersCoinByOut(previousOwner);

    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    (,,,,upgradeClass, unitId, upgradeValue) = rare.getRareInfo(rareId);
    
    upgradeUnitMultipliers(msg.sender, upgradeClass, unitId, upgradeValue); 
    removeUnitMultipliers(previousOwner, upgradeClass, unitId, upgradeValue); 

    // Splitbid/Overbid
    if (ethCost > msg.value) {
      cards.setCoinBalance(msg.sender,SafeMath.sub(ethCost,msg.value),0,false);
    } else if (msg.value > ethCost) {
      // Store overbid in their balance
      cards.setCoinBalance(msg.sender,SafeMath.sub(msg.value,ethCost),0,true);
    }  
    // Distribute ethCost
    uint256 devFund = uint256(SafeMath.div(ethCost, 20)); // 5% fee on purchases (marketing, gameplay & maintenance) 
    uint256 dividends = uint256(SafeMath.div(ethCost,20)); // 5% goes to pool 

    cards.setTotalEtherPool(dividends,0,true);
    cards.setCoinBalance(owner,devFund,0,true); 
        
    // Transfer / update rare item
    rare.transferToken(previousOwner,msg.sender,rareId); 
    rare.setRarePrice(rareId,SafeMath.div(SafeMath.mul(ethCost,5),4));

    cards.setCoinBalance(previousOwner,SafeMath.sub(ethCost,SafeMath.add(dividends,devFund)),0,true);

    //players
    if (cards.getUintsOwnerCount(msg.sender)<=0) {
      cards.AddPlayers(msg.sender);
    }
   
    cards.setUintsOwnerCount(msg.sender,1,true);
    cards.setUintsOwnerCount(previousOwner,1,false);

    //tell the world
    BuyRareCard(msg.sender, previousOwner, rareId, ethCost);
  }
  
  /// sell out cards ,upgrade cards can not be sold
  function sellCards(uint256 unitId, uint256 amount) external {
    require(cards.getGameStarted());
    uint256 existing = cards.getOwnedCount(msg.sender,unitId);
    require(existing >= amount && amount>0); 
    existing = SafeMath.sub(existing,amount);

    uint256 coinChange;
    uint256 decreaseCoin;
    uint256 schemaUnitId;
    uint256 coinProduction;
    uint256 coinCost;
    uint256 ethCost;
    bool sellable;
    if (unitId>=40) {
      (schemaUnitId,coinCost,ethCost, sellable) = schema.getBattleCardInfo(unitId, existing, amount);
    } else {
      (schemaUnitId, coinProduction, coinCost, ethCost, sellable) = schema.getCardInfo(unitId, existing, amount);
    }
    if (ethCost>0) {
      require(unitsOwnedOfEth[msg.sender][unitId]>=amount);
    }
    //cards can be sold
    require(sellable);
    if (coinCost>0) {
      coinChange = SafeMath.add(cards.balanceOfUnclaimed(msg.sender), SafeMath.div(SafeMath.mul(coinCost,70),100)); // Claim unsaved goo whilst here
    } else {
      coinChange = cards.balanceOfUnclaimed(msg.sender); //if 0
    }

    cards.setLastJadeSaveTime(msg.sender); 
    cards.setRoughSupply(coinChange);  
    cards.setJadeCoin(msg.sender, coinChange, true); //  70% to users

    decreaseCoin = cards.getUnitsInProduction(msg.sender, unitId, amount); 
    
    if (coinProduction > 0) { 
      cards.reducePlayersJadeProduction(msg.sender, decreaseCoin);
      //reduct production
      cards.setUintCoinProduction(msg.sender,unitId,decreaseCoin,false); 
    }

    if (ethCost > 0) { // Premium units sell for 70% of buy cost
      cards.setCoinBalance(msg.sender,SafeMath.div(SafeMath.mul(ethCost,70),100),0,true);
    }

    cards.setOwnedCount(msg.sender,unitId,amount,false); //subscriber
    cards.setUintsOwnerCount(msg.sender,amount,false);
    if (ethCost>0) {
      unitsOwnedOfEth[msg.sender][unitId] = SafeMath.sub(unitsOwnedOfEth[msg.sender][unitId],amount);
    }
    //tell the world
    UnitSold(msg.sender, unitId, amount);
  }

  // withraw ether
  function withdrawAmount (uint256 _amount) public onlyOwner {
    require(_amount<= this.balance);
    owner.transfer(_amount);
  }
   /// withdraw ether to wallet
  function withdrawEtherFromTrade(uint256 amount) external {
    require(amount <= cards.coinBalanceOf(msg.sender,0));
    cards.setCoinBalance(msg.sender,amount,0,false);
    msg.sender.transfer(amount);
  }

  function getCanSellUnit(address _address,uint256 unitId) external view returns (uint256) {
    return unitsOwnedOfEth[_address][unitId];
  }
}