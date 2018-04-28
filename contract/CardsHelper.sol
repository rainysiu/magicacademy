pragma solidity ^0.4.18;
import "./SafeMath.sol";
import "./CardsAccess.sol";
import "./GameConfigInterface.sol";
import "./CardsInterface.sol";

contract CardsHelper is CardsAccess {

  CardsInterface public cards ;
  GameConfigInterface public schema;

  function setCardsAddress(address _address) external onlyOwner {
    cards = CardsInterface(_address);
  }

   //设置游戏参数
  function setConfigAddress(address _address) external onlyOwner {
    schema = GameConfigInterface(_address);
  }

/// 增加权值
  function upgradeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) internal {
    uint256 productionGain;
    if (upgradeClass == 0) {
      cards.setUnitCoinProductionIncreases(player, unitId, upgradeValue,"add");
      productionGain = (cards.getOwnedCount(player,unitId) * upgradeValue * (10 + cards.getUnitCoinProductionMultiplier(player,unitId))) / 10;
      cards.setUintCoinProduction(player,unitId,productionGain,"add"); 
      cards.increasePlayersJadeProduction(player,productionGain);
    } else if (upgradeClass == 1) {
      cards.setUnitCoinProductionMultiplier(player,unitId,upgradeValue,"add");
      productionGain = (cards.getOwnedCount(player,unitId) * upgradeValue * (schema.unitCoinProduction(unitId) + cards.getUnitCoinProductionIncreases(player,unitId))) / 10;
      cards.setUintCoinProduction(player,unitId,productionGain,"add");
      cards.increasePlayersJadeProduction(player,productionGain);
    } else if (upgradeClass == 2) {
      cards.setUnitAttackIncreases(player,unitId,upgradeValue,"add");
    } else if (upgradeClass == 3) {
      cards.setUnitAttackMultiplier(player,unitId,upgradeValue,"add");
    } else if (upgradeClass == 4) {
      cards.setUnitDefenseIncreases(player,unitId,upgradeValue,"add");
    } else if (upgradeClass == 5) {
      cards.setunitDefenseMultiplier(player,unitId,upgradeValue,"add");
    } else if (upgradeClass == 6) {
      cards.setUnitJadeStealingIncreases(player,unitId,upgradeValue,"add");
    } else if (upgradeClass == 7) {
      cards.setUnitJadeStealingMultiplier(player,unitId,upgradeValue,"add");
    }
  }
  /// 移除加权值
  function removeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) internal {
    uint256 productionLoss;
    if (upgradeClass == 0) {
      cards.setUnitCoinProductionIncreases(player, unitId, upgradeValue,"sub");
      productionLoss = (cards.getOwnedCount(player,unitId) * upgradeValue * (10 + cards.getUnitCoinProductionMultiplier(player,unitId))) / 10;
      cards.setUintCoinProduction(player,unitId,productionLoss,"sub"); 
      cards.reducePlayersJadeProduction(player, productionLoss);
    } else if (upgradeClass == 1) {
      cards.setUnitCoinProductionMultiplier(player,unitId,upgradeValue,"sub");
      productionLoss = (cards.getOwnedCount(player,unitId) * upgradeValue * (schema.unitCoinProduction(unitId) + cards.getUnitCoinProductionIncreases(player,unitId))) / 10;
      cards.setUintCoinProduction(player,unitId,productionLoss,"sub"); 
      cards.reducePlayersJadeProduction(player, productionLoss);
    } else if (upgradeClass == 2) {
      cards.setUnitAttackIncreases(player,unitId,upgradeValue,"sub");
    } else if (upgradeClass == 3) {
      cards.setUnitAttackMultiplier(player,unitId,upgradeValue,"sub");
    } else if (upgradeClass == 4) {
      cards.setUnitDefenseIncreases(player,unitId,upgradeValue,"sub");
    } else if (upgradeClass == 5) {
      cards.setunitDefenseMultiplier(player,unitId,upgradeValue,"sub");
    } else if (upgradeClass == 6) { 
      cards.setUnitJadeStealingIncreases(player,unitId,upgradeValue,"sub");
    } else if (upgradeClass == 7) {
      cards.setUnitJadeStealingMultiplier(player,unitId,upgradeValue,"sub");
    }
  }
}