pragma solidity ^0.4.18;
interface GameConfigInterface {
  function getMaxCAP() external returns (uint8);
  function getCostForCards(uint256 cardId, uint256 existing, uint256 amount) public constant returns (uint256);
  function getCostForUprade(uint256 cardId, uint256 existing, uint256 amount) public constant returns (uint256);
  function getWeakenedDefensePower(uint256 defendingPower) external constant returns (uint256);
  function unitEthCost(uint256 cardId) external constant returns (uint256);
  function unitCoinProduction(uint256 cardId) external constant returns (uint256);
  function unitAttack(uint256 cardId) external constant returns (uint256);
  function unitDefense(uint256 cardId) external constant returns (uint256);
  function unitStealingCapacity(uint256 cardId) external constant returns (uint256);
  function rareStartPrice(uint256 rareId) external constant returns (uint256);
  function productionCardIdRange() external constant returns (uint256, uint256);
  function battleCardIdRange() external constant returns (uint256, uint256);
  function upgradeIdRange() external constant returns (uint256, uint256);
  function rareIdRange() external constant returns (uint256, uint256);
  function getRareLen() external constant returns (uint256); 
  function getCardsInfo(uint256 cardId) external constant returns (
    uint256 baseCoinCost,
    uint256 coinCostIncreaseHalf,
    uint256 ethCost, 
    uint256 baseCoinProduction, 
    uint256 attackValue,
    uint256 defenseValue,
    uint256 coinStealingCapacity,
    bool unitSellable 
  );
  function getCardInfo(uint256 cardId, uint256 existing, uint256 amount) external constant returns (uint256, uint256, uint256, uint256, bool);
  function getUpgradeInfo(uint256 upgradecardId) external constant returns (
    uint256 coinCost, 
    uint256 ethCost, 
    uint256 upgradeClass, 
    uint256 cardId, 
    uint256 upgradeValue
  );

  function getRareInfo(uint256 rareId) external view returns (
    uint256 rareClass,
    uint256 cardId,
    uint256 rareValue
  );
  function getUpgradeCardsInfo(uint256 upgradecardId,uint256 existing) external constant returns (
    uint256 coinCost, 
    uint256 ethCost, 
    uint256 upgradeClass, 
    uint256 cardId, 
    uint256 upgradeValue
  );
}