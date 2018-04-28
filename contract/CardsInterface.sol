pragma solidity ^0.4.18;

interface CardsInterface {
    function getJadeProduction(address player) external constant returns (uint256);
    function getPlayersBattlePower(address attacker, address defender) external constant returns (
    uint256 attackingPower, 
    uint256 defendingPower, 
    uint256 stealingPower);

    function getGameStarted() external constant returns (bool);
    function balanceOf(address player) external constant returns(uint256);
    function balanceOfUnclaimed(address player) external constant returns (uint256);
    function etherBalanceOf(address player) external constant returns(uint256);

    function addEthBalance(address player, uint256 eth) external returns (uint256);
    function subEthBalance(address player, uint256 eth) external returns (uint256);
    function withdrawEther(address player, uint256 amount) external;

    function addJadeCoin(address player, uint256 coin) external returns (uint256);
    function subJadeCoin(address player, uint256 coin) external returns (uint256);
    function setJadeCoinZero(address player) external;
    function setLastJadeSaveTime(address player) external;
    function setRoughSupply(uint256 iroughSupply) external;

    function updatePlayersCoinByPurchase(address player, uint256 purchaseCost) external;
    function updatePlayersCoinByOut(address player) external;

    function increasePlayersJadeProduction(address player, uint256 increase) external;
    function reducePlayersJadeProduction(address player, uint256 decrease) external;

    function getRareItemsOwner(uint256 rareId) external view returns (address);
    function getRareItemsPrice(uint256 rareId) external view returns (uint256);
    function setRareOwner(uint256 _rareId, address _address) external;
    function setRarePrice(uint256 _rareId, uint256 _price) external;

    function getUintsOwnerCount(address _address) external view returns (uint256);
    function setUintsOwnerCount(address _address, uint256 amount, string flag) external;

    function getOwnedCount(address player, uint256 cardId) external view returns (uint256);
    function setOwnedCount(address player, uint256 cardId, uint256 amount, string flag) external;

    function getUpgradesOwned(address player, uint256 upgradeId) external view returns (uint256);
    function setUpgradesOwned(address player, uint256 upgradeId) external;
    
    function addTotalEtherPool(uint256 inEth) external;
    function subTotalEtherPool(uint256 inEth) external;
    function getTotalEtherPool() external view returns (uint256);

    function setNextSnapshotTime(uint256 iTime) external;
    function getNextSnapshotTime() external view;

    function AddPlayers(address _address) external;

    function getUnitsProduction(address player, uint256 cardId, uint256 amount) external constant returns (uint256);
    function getUnitsAttack(address player, uint256 cardId, uint256 amount) external constant returns (uint256);
    function getUnitsDefense(address player, uint256 cardId, uint256 amount) external constant returns (uint256);
    function getUnitsStealingCapacity(address player, uint256 cardId, uint256 amount) external constant returns (uint256);

    function getUnitCoinProductionIncreases(address _address, uint256 cardId) external view returns (uint256);
    function setUnitCoinProductionIncreases(address _address, uint256 cardId, uint256 iValue,string flag) external;

    function getUnitCoinProductionMultiplier(address _address, uint256 cardId) external view returns (uint256);
    function setUnitCoinProductionMultiplier(address _address, uint256 cardId, uint256 iValue,string flag) external;

    function setUnitAttackIncreases(address _address, uint256 cardId, uint256 iValue,string flag) external;
    function setUnitAttackMultiplier(address _address, uint256 cardId, uint256 iValue,string flag) external;
    function setUnitDefenseIncreases(address _address, uint256 cardId, uint256 iValue,string flag) external;
    function setunitDefenseMultiplier(address _address, uint256 cardId, uint256 iValue,string flag) external;
    function setUnitJadeStealingIncreases(address _address, uint256 cardId, uint256 iValue,string flag) external;
    function setUnitJadeStealingMultiplier(address _address, uint256 cardId, uint256 iValue,string flag) external;

    function setUintCoinProduction(address _address, uint256 cardId, uint256 iValue,string flag) external;
    function getUintCoinProduction(address _address, uint256 cardId) external returns (uint256);

    function getUnitsInProduction(address player, uint256 unitId, uint256 amount) external constant returns (uint256); 
}