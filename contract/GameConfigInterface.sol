pragma solidity ^0.4.18;
interface GameConfigInterface {
  function getMaxCAP() external returns (uint256);
  function getCostForCards(uint256 cardId, uint256 existing, uint256 amount) external constant returns (uint256);
  function getCostForBattleCards(uint256 cardId, uint256 existing, uint256 amount) external constant returns (uint256);
  function getCostForUprade(uint256 cardId, uint256 existing, uint256 amount) external constant returns (uint256);
  function getWeakenedDefensePower(uint256 defendingPower) external constant returns (uint256);
  function unitEthCost(uint256 cardId) external constant returns (uint256);
  function unitBattleEthCost(uint256 cardId) external constant returns (uint256);
  function unitPLATCost(uint256 cardId) external constant returns (uint256);
  function unitBattlePLATCost(uint256 cardId) external constant returns (uint256);
  function unitCoinProduction(uint256 cardId) external constant returns (uint256);
  function unitAttack(uint256 cardId) external constant returns (uint256);
  function unitDefense(uint256 cardId) external constant returns (uint256);
  function unitStealingCapacity(uint256 cardId) external constant returns (uint256);
  function productionCardIdRange() external constant returns (uint256, uint256);
  function battleCardIdRange() external constant returns (uint256, uint256);
  function upgradeIdRange() external constant returns (uint256, uint256);
  function getCardsInfo(uint256 cardId) external constant returns (
    uint256 baseCoinCost,
    uint256 coinCostIncreaseHalf,
    uint256 ethCost, 
    uint256 baseCoinProduction,
    uint256 platCost, 
    bool  unitSellable
  );
  //for purchase;
  function getCardInfo(uint256 cardId, uint256 existing, uint256 amount) external constant returns (uint256, uint256, uint256, uint256, bool);
  function getBattleCardInfo(uint256 cardId, uint256 existing, uint256 amount) external constant returns (uint256, uint256, uint256, bool);
  function getBattleCardsInfo(uint256 cardId) external constant returns (
    uint256 baseCoinCost,
    uint256 coinCostIncreaseHalf,
    uint256 ethCost, 
    uint256 attackValue,
    uint256 defenseValue,
    uint256 coinStealingCapacity,
    uint256 platCost,
    bool  unitSellable
  );
  function getUpgradeCardsInfo(uint256 upgradecardId,uint256 existing) external constant returns (
    uint256 coinCost, 
    uint256 ethCost, 
    uint256 upgradeClass, 
    uint256 cardId, 
    uint256 upgradeValue,
    uint256 platCost
  );
}