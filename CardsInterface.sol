pragma solidity ^0.4.18;

interface CardsInterface {
    function getJadeProduction(address player) external constant returns (uint256);
    function getUpgradeValue(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) external view returns (uint256);
    function getGameStarted() external constant returns (bool);
    function balanceOf(address player) external constant returns(uint256);
    function balanceOfUnclaimed(address player) external constant returns (uint256);
    function coinBalanceOf(address player,uint8 itype) external constant returns(uint256);

    function setCoinBalance(address player, uint256 eth, uint8 itype, bool iflag) external;
    function setJadeCoin(address player, uint256 coin, bool iflag) external;
    function setJadeCoinZero(address player) external;

    function setLastJadeSaveTime(address player) external;
    function setRoughSupply(uint256 iroughSupply) external;

    function updatePlayersCoinByPurchase(address player, uint256 purchaseCost) external;
    function updatePlayersCoinByOut(address player) external;

    function increasePlayersJadeProduction(address player, uint256 increase) external;
    function reducePlayersJadeProduction(address player, uint256 decrease) external;

    function getUintsOwnerCount(address _address) external view returns (uint256);
    function setUintsOwnerCount(address _address, uint256 amount, bool iflag) external;

    function getOwnedCount(address player, uint256 cardId) external view returns (uint256);
    function setOwnedCount(address player, uint256 cardId, uint256 amount, bool iflag) external;

    function getUpgradesOwned(address player, uint256 upgradeId) external view returns (uint256);
    function setUpgradesOwned(address player, uint256 upgradeId) external;
    
    function getTotalEtherPool(uint8 itype) external view returns (uint256);
    function setTotalEtherPool(uint256 inEth, uint8 itype, bool iflag) external;

    function setNextSnapshotTime(uint256 iTime) external;
    function getNextSnapshotTime() external view;

    function AddPlayers(address _address) external;
    function getTotalUsers()  external view returns (uint256);
    function getRanking() external view returns (address[] addr, uint256[] _arr);
    function getAttackRanking() external view returns (address[] addr, uint256[] _arr);

    function getUnitsProduction(address player, uint256 cardId, uint256 amount) external constant returns (uint256);

    function getUnitCoinProductionIncreases(address _address, uint256 cardId) external view returns (uint256);
    function setUnitCoinProductionIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external;
     function getUnitCoinProductionMultiplier(address _address, uint256 cardId) external view returns (uint256);
    function setUnitCoinProductionMultiplier(address _address, uint256 cardId, uint256 iValue,bool iflag) external;
     function setUnitAttackIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external;
    function setUnitAttackMultiplier(address _address, uint256 cardId, uint256 iValue,bool iflag) external;
    function setUnitDefenseIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external;
    function setunitDefenseMultiplier(address _address, uint256 cardId, uint256 iValue,bool iflag) external;
    
    function setUnitJadeStealingIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external;
    function setUnitJadeStealingMultiplier(address _address, uint256 cardId, uint256 iValue,bool iflag) external;

    function setUintCoinProduction(address _address, uint256 cardId, uint256 iValue,bool iflag) external;
    function getUintCoinProduction(address _address, uint256 cardId) external returns (uint256);

    function getUnitsInProduction(address player, uint256 unitId, uint256 amount) external constant returns (uint256);
    function getPlayersBattleStats(address player) public constant returns (
    uint256 attackingPower, 
    uint256 defendingPower, 
    uint256 stealingPower,
    uint256 battlePower); 
}