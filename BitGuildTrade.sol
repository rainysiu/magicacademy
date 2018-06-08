pragma solidity ^0.4.18;
import "./SafeMath.sol";
import "./BitGuildHelper.sol";

interface BitGuildTokenInterface { // implements ERC20Interface
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
/// @notice Purchase on BitGuild
/// @author rainysiu rainy@livestar.com
contract BitGuildTrade is BitGuildHelper {
  BitGuildTokenInterface public tokenContract;

  event UnitBought(address player, uint256 unitId, uint256 amount);
  event UpgradeCardBought(address player, uint256 upgradeId);
  event BuyRareCard(address player, address previous, uint256 rareId,uint256 iPrice);
  event UnitSold(address player, uint256 unitId, uint256 amount);

  mapping(address => mapping(uint256 => uint256)) unitsOwnedOfPLAT; //cards bought through plat
  function() external payable {
    revert();
  }
  function setBitGuildToken(address _tokenContract) external {
    tokenContract = BitGuildTokenInterface(_tokenContract);
  } 

  function kill() public onlyOwner {
    tokenContract.transferFrom(this, msg.sender, tokenContract.balanceOf(this));
    selfdestruct(msg.sender); //end execution, destroy current contract and send funds to a
  }  
  /// @notice Returns all the relevant information about a specific tokenId.
  /// val1:flag,val2:id,val3:amount
  function _getExtraParam(bytes _extraData) private pure returns(uint256 val1,uint256 val2,uint256 val3) {
    if (_extraData.length == 2) {
      val1 = uint256(_extraData[0]);
      val2 = uint256(_extraData[1]);
      val3 = 1; 
    } else if (_extraData.length == 3) {
      val1 = uint256(_extraData[0]);
      val2 = uint256(_extraData[1]);
      val3 = uint256(_extraData[2]);
    }
    
  }
  
  function receiveApproval(address _player, uint256 _value, address _tokenContractAddr, bytes _extraData) external {
    require(msg.sender == _tokenContractAddr);
    require(_extraData.length >=1);
    require(tokenContract.transferFrom(_player, address(this), _value));
    uint256 flag;
    uint256 unitId;
    uint256 amount;
    (flag,unitId,amount) = _getExtraParam(_extraData);

    if (flag==1) {
      buyPLATCards(_player, _value, unitId, amount);  // 1-39
    } else if (flag==3) {
      buyUpgradeCard(_player, _value, unitId);  // >=1
    } else if (flag==4) {
      buyRareItem(_player, _value, unitId); //rarecard
    } 
  } 

  function buyPLATCards(address _player, uint256 _platValue, uint256 _cardId, uint256 _amount) internal {
    require(cards.getGameStarted());
    require(_amount>=1);
    uint256 existing = cards.getOwnedCount(_player,_cardId);
    require(existing < schema.getMaxCAP());    
    
    uint256 iAmount;
    if (SafeMath.add(existing, _amount) > schema.getMaxCAP()) {
      iAmount = SafeMath.sub(schema.getMaxCAP(),existing);
    } else {
      iAmount = _amount;
    }
    uint256 coinProduction;
    uint256 coinCost;
    uint256 ethCost;

    if (_cardId>=1 && _cardId<=39) {
      coinProduction = schema.unitCoinProduction(_cardId);
      coinCost = schema.getCostForCards(_cardId, existing, iAmount);
      ethCost = SafeMath.mul(schema.unitPLATCost(_cardId),iAmount);  // get platprice
    } else if (_cardId>=40) {
      coinCost = schema.getCostForBattleCards(_cardId, existing, iAmount);
      ethCost = SafeMath.mul(schema.unitBattlePLATCost(_cardId),iAmount);  // get platprice
    }
    require(ethCost>0);
    require(SafeMath.add(cards.coinBalanceOf(_player,1),_platValue) >= ethCost);
    require(cards.balanceOf(_player) >= coinCost);   

    // Update players jade  
    cards.updatePlayersCoinByPurchase(_player, coinCost);

    if (ethCost > _platValue) {
      cards.setCoinBalance(_player,SafeMath.sub(ethCost,_platValue),1,false);
    } else if (_platValue > ethCost) {
      // Store overbid in their balance
      cards.setCoinBalance(_player,SafeMath.sub(_platValue,ethCost),1,true);
    } 

    uint256 devFund = uint256(SafeMath.div(ethCost,20)); // 5% fee
    cards.setTotalEtherPool(uint256(SafeMath.div(ethCost,4)),1,true);  // 20% to pool
    cards.setCoinBalance(owner,devFund,1,true);  
    
    if (coinProduction > 0) {
      cards.increasePlayersJadeProduction(_player, cards.getUnitsProduction(_player, _cardId, iAmount)); 
      cards.setUintCoinProduction(_player,_cardId,cards.getUnitsProduction(_player, _cardId, iAmount),true); 
    }
    
    if (cards.getUintsOwnerCount(_player)<=0) {
      cards.AddPlayers(_player);
    }
    cards.setUintsOwnerCount(_player,iAmount, true);
    cards.setOwnedCount(_player,_cardId,iAmount,true);
    unitsOwnedOfPLAT[_player][_cardId] = SafeMath.add(unitsOwnedOfPLAT[_player][_cardId],iAmount);
    //event
    UnitBought(_player, _cardId, iAmount);
  }

  /// upgrade cards-- jade + plat
  function buyUpgradeCard(address _player, uint256 _platValue,uint256 _upgradeId) internal {
    require(cards.getGameStarted());
    require(_upgradeId>=1);
    uint256 existing = cards.getUpgradesOwned(_player,_upgradeId);
    require(existing<=5);  // v1 - v6
    uint256 coinCost;
    uint256 ethCost;
    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    uint256 platCost;
    (coinCost, ethCost, upgradeClass, unitId, upgradeValue,platCost) = schema.getUpgradeCardsInfo(_upgradeId,existing);

    require(platCost>0);
    if (platCost > 0) {
      require(SafeMath.add(cards.coinBalanceOf(_player,1),_platValue) >= platCost); 

      if (platCost > _platValue) { // They can use their balance instead
        cards.setCoinBalance(_player, SafeMath.sub(platCost,_platValue),1,false);
      } else if (platCost < _platValue) {  
        cards.setCoinBalance(_player,SafeMath.sub(_platValue,platCost),1,true);
    } 
      

      // defund 5%，upgrade card can not be sold，
      uint256 devFund = uint256(SafeMath.div(platCost, 20)); // 5% fee on purchases (marketing, gameplay & maintenance)
      cards.setTotalEtherPool(SafeMath.sub(platCost,devFund),1,true); // Rest goes to div pool (Can't sell upgrades)
      cards.setCoinBalance(owner,devFund,1,true);  
    }
        
     // Update 
    require(cards.balanceOf(_player) >= coinCost);  
    cards.updatePlayersCoinByPurchase(_player, coinCost);
    
    //add weight
    upgradeUnitMultipliers(_player, upgradeClass, unitId, upgradeValue);  
    cards.setUpgradesOwned(_player,_upgradeId); // upgrade level up

     //add user to userlist
    if (cards.getUintsOwnerCount(_player)<=0) {
      cards.AddPlayers(_player);
    }
 
    UpgradeCardBought(_player, _upgradeId);
  }

  // Allows someone to send ether and obtain the token
  function buyRareItem(address _player, uint256 _platValue,uint256 _rareId) internal {
    require(cards.getGameStarted());        
    address previousOwner = rare.getRareItemsOwner(_rareId);  // rare card
    require(previousOwner != 0);
    require(_player!=previousOwner);  // can not buy from itself
    
    uint256 ethCost = rare.getRareItemsPLATPrice(_rareId); // get plat cost
    uint256 totalCost = SafeMath.add(cards.coinBalanceOf(_player,1),_platValue);
    require(totalCost >= ethCost); 
    // We have to claim buyer/sellder's goo before updating their production values 
    cards.updatePlayersCoinByOut(_player);
    cards.updatePlayersCoinByOut(previousOwner);

    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    (,,,,upgradeClass, unitId, upgradeValue) = rare.getRarePLATInfo(_rareId);
    
    // modify weight
    upgradeUnitMultipliers(_player, upgradeClass, unitId, upgradeValue); 
    removeUnitMultipliers(previousOwner, upgradeClass, unitId, upgradeValue); 

    // Splitbid/Overbid
    if (ethCost > _platValue) {
      cards.setCoinBalance(_player,SafeMath.sub(ethCost,_platValue),1,false);
    } else if (_platValue > ethCost) {
      // Store overbid in their balance
      cards.setCoinBalance(_player,SafeMath.sub(_platValue,ethCost),1,true);
    }  
    // Distribute ethCost  uint256 devFund = ethCost / 50; 
    uint256 devFund = uint256(SafeMath.div(ethCost, 20)); // 5% fee on purchases (marketing, gameplay & maintenance)  抽成2%
    uint256 dividends = uint256(SafeMath.div(ethCost,20)); // 5% goes to pool 

    cards.setTotalEtherPool(dividends,1,true);  // 5% to pool
    cards.setCoinBalance(owner,devFund,1,true);  // 5% fee
        
    // Transfer / update rare item
    rare.transferToken(previousOwner,_player,_rareId); 
    rare.setRarePrice(_rareId,SafeMath.div(SafeMath.mul(rare.getRareItemsPrice(_rareId),5),4));
    
    cards.setCoinBalance(previousOwner,SafeMath.sub(ethCost,SafeMath.add(dividends,devFund)),1,true);
    
    if (cards.getUintsOwnerCount(_player)<=0) {
      cards.AddPlayers(_player);
    }
   
    cards.setUintsOwnerCount(_player,1,true);
    cards.setUintsOwnerCount(previousOwner,1,true);

    //tell the world
    BuyRareCard(_player, previousOwner, _rareId, ethCost);
  }

  /// refunds 75% since no transfer between bitguild and player,no need to call approveAndCall
  function sellCards( uint256 _unitId, uint256 _amount) external {
    require(cards.getGameStarted());
    uint256 existing = cards.getOwnedCount(msg.sender,_unitId);
    require(existing >= _amount && _amount>0); 
    existing = SafeMath.sub(existing,_amount);
    uint256 coinChange;
    uint256 decreaseCoin;
    uint256 schemaUnitId;
    uint256 coinProduction;
    uint256 coinCost;
    uint256 ethCost;
    bool sellable;
    if (_unitId>=40) { // upgrade card
      (schemaUnitId,coinCost,, sellable) = schema.getBattleCardInfo(_unitId, existing, _amount);
      ethCost = SafeMath.mul(schema.unitBattlePLATCost(_unitId),_amount);
    } else {
      (schemaUnitId, coinProduction, coinCost, , sellable) = schema.getCardInfo(_unitId, existing, _amount);
      ethCost = SafeMath.mul(schema.unitPLATCost(_unitId),_amount); // plat 
    }
    require(sellable);  // can be refunded
    if (ethCost>0) {
      require(unitsOwnedOfPLAT[msg.sender][_unitId]>=_amount);
    }
    if (coinCost>0) {
      coinChange = SafeMath.add(cards.balanceOfUnclaimed(msg.sender), SafeMath.div(SafeMath.mul(coinCost,70),100)); // Claim unsaved goo whilst here
    } else {
      coinChange = cards.balanceOfUnclaimed(msg.sender); 
    }

    cards.setLastJadeSaveTime(msg.sender); 
    cards.setRoughSupply(coinChange);  
    cards.setJadeCoin(msg.sender, coinChange, true); // refund 75% Jadecoin to player 

    decreaseCoin = cards.getUnitsInProduction(msg.sender, _unitId, _amount);
  
    if (coinProduction > 0) { 
      cards.reducePlayersJadeProduction(msg.sender, decreaseCoin);
      //update the speed of jade minning
      cards.setUintCoinProduction(msg.sender,_unitId,decreaseCoin,false); 
    }

    if (ethCost > 0) { // Premium units sell for 75% of buy cost
      cards.setCoinBalance(msg.sender,SafeMath.div(SafeMath.mul(ethCost,70),100),1,true);
    }

    cards.setOwnedCount(msg.sender,_unitId,_amount,false); 
    cards.setUintsOwnerCount(msg.sender,_amount,false);
    if (ethCost>0) {
      unitsOwnedOfPLAT[msg.sender][_unitId] = SafeMath.sub(unitsOwnedOfPLAT[msg.sender][_unitId],_amount);
    }
    //tell the world
    UnitSold(msg.sender, _unitId, _amount);
  }

  //@notice for player withdraw
  function withdrawEtherFromTrade(uint256 amount) external {
    require(amount <= cards.coinBalanceOf(msg.sender,1));
    cards.setCoinBalance(msg.sender,amount,1,false);
    tokenContract.transfer(msg.sender,amount);
  } 

  //@notice withraw all PLAT by dev
  function withdrawToken(uint256 amount) external onlyOwner {
    uint256 balance = tokenContract.balanceOf(this);
    require(balance > 0 && balance >= amount);
    cards.setCoinBalance(msg.sender,amount,1,false);
    tokenContract.transfer(msg.sender, amount);
  }

  function getCanSellUnit(address _address, uint256 unitId) external view returns (uint256) {
    return unitsOwnedOfPLAT[_address][unitId];
  }

}
