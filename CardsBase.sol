pragma solidity ^0.4.18;
import "./JadeCoin.sol";

interface GameConfigInterface {
  function productionCardIdRange() external constant returns (uint256, uint256);
  function battleCardIdRange() external constant returns (uint256, uint256);
  function upgradeIdRange() external constant returns (uint256, uint256);
  function unitCoinProduction(uint256 cardId) external constant returns (uint256);
  function unitAttack(uint256 cardId) external constant returns (uint256);
  function unitDefense(uint256 cardId) external constant returns (uint256);
  function unitStealingCapacity(uint256 cardId) external constant returns (uint256);
}

/// @notice define the players,cards,jadecoin
/// @author rainysiu rainy@livestar.com
/// @dev MagicAcademy Games 

contract CardsBase is JadeCoin {

  // player  
  struct Player {
    address owneraddress;
  }

  Player[] players;
  bool gameStarted;
  
  GameConfigInterface public schema;

  // Stuff owned by each player
  mapping(address => mapping(uint256 => uint256)) public unitsOwned;  //number of normal card
  mapping(address => mapping(uint256 => uint256)) public upgradesOwned;  //Lv of upgrade card

  mapping(address => uint256) public uintsOwnerCount; // total number of cards
  mapping(address=> mapping(uint256 => uint256)) public uintProduction;  //card's production 单张卡牌总产量

  // Rares & Upgrades (Increase unit's production / attack etc.)
  mapping(address => mapping(uint256 => uint256)) public unitCoinProductionIncreases; // Adds to the coin per second
  mapping(address => mapping(uint256 => uint256)) public unitCoinProductionMultiplier; // Multiplies the coin per second
  mapping(address => mapping(uint256 => uint256)) public unitAttackIncreases;
  mapping(address => mapping(uint256 => uint256)) public unitAttackMultiplier;
  mapping(address => mapping(uint256 => uint256)) public unitDefenseIncreases;
  mapping(address => mapping(uint256 => uint256)) public unitDefenseMultiplier;
  mapping(address => mapping(uint256 => uint256)) public unitJadeStealingIncreases;
  mapping(address => mapping(uint256 => uint256)) public unitJadeStealingMultiplier;

  //setting configuration
  function setConfigAddress(address _address) external onlyOwner {
    schema = GameConfigInterface(_address);
  }

  /// start game
  function beginGame() external onlyOwner {
    require(!gameStarted);
    gameStarted = true; 
  }
  function getGameStarted() external constant returns (bool) {
    return gameStarted;
  }
  function AddPlayers(address _address) external onlyAccess { 
    Player memory _player= Player({
      owneraddress: _address
    });
    players.push(_player);
  }

  /// @notice ranking of production
  /// @notice rainysiu
  function getRanking() external view returns (address[], uint256[]) {
    uint256 len = players.length;
    uint256[] memory arr = new uint256[](len);
    address[] memory arr_addr = new address[](len);

    uint counter =0;
    for (uint k=0;k<len; k++){
      arr[counter] =  getJadeProduction(players[k].owneraddress);
      arr_addr[counter] = players[k].owneraddress;
      counter++;
    }

    for(uint i=0;i<len-1;i++) {
      for(uint j=0;j<len-i-1;j++) {
        if(arr[j]<arr[j+1]) {
          uint256 temp = arr[j];
          address temp_addr = arr_addr[j];
          arr[j] = arr[j+1];
          arr[j+1] = temp;
          arr_addr[j] = arr_addr[j+1];
          arr_addr[j+1] = temp_addr;
        }
      }
    }
    return (arr_addr,arr);
  }

  /// @notice battle power ranking
  /// @notice rainysiu
  function getAttackRanking() external view returns (address[], uint256[]) {
    uint256 len = players.length;
    uint256[] memory arr = new uint256[](len);
    address[] memory arr_addr = new address[](len);

    uint counter =0;
    for (uint k=0;k<len; k++){
      (,,,arr[counter]) = getPlayersBattleStats(players[k].owneraddress);
      arr_addr[counter] = players[k].owneraddress;
      counter++;
    }

    for(uint i=0;i<len-1;i++) {
      for(uint j=0;j<len-i-1;j++) {
        if(arr[j]<arr[j+1]) {
          uint256 temp = arr[j];
          address temp_addr = arr_addr[j];
          arr[j] = arr[j+1];
          arr[j+1] = temp;
          arr_addr[j] = arr_addr[j+1];
          arr_addr[j+1] = temp_addr;
        }
      }
    }
    return(arr_addr,arr);
  } 

  //total users
  function getTotalUsers()  external view returns (uint256) {
    return players.length;
  }
 
  /// UnitsProuction
  function getUnitsProduction(address player, uint256 unitId, uint256 amount) external constant returns (uint256) {
    return (amount * (schema.unitCoinProduction(unitId) + unitCoinProductionIncreases[player][unitId]) * (10 + unitCoinProductionMultiplier[player][unitId])) / 10; 
  } 

  /// one card's production
  function getUnitsInProduction(address player, uint256 unitId, uint256 amount) external constant returns (uint256) {
    return SafeMath.div(SafeMath.mul(amount,uintProduction[player][unitId]),unitsOwned[player][unitId]);
  } 

  /// UnitsAttack
  function getUnitsAttack(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
    return (amount * (schema.unitAttack(unitId) + unitAttackIncreases[player][unitId]) * (10 + unitAttackMultiplier[player][unitId])) / 10;
  }
  /// UnitsDefense
  function getUnitsDefense(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
    return (amount * (schema.unitDefense(unitId) + unitDefenseIncreases[player][unitId]) * (10 + unitDefenseMultiplier[player][unitId])) / 10;
  }
  /// UnitsStealingCapacity
  function getUnitsStealingCapacity(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
    return (amount * (schema.unitStealingCapacity(unitId) + unitJadeStealingIncreases[player][unitId]) * (10 + unitJadeStealingMultiplier[player][unitId])) / 10;
  }
 
  // player's attacking & defending & stealing & battle power
  function getPlayersBattleStats(address player) public constant returns (
    uint256 attackingPower, 
    uint256 defendingPower, 
    uint256 stealingPower,
    uint256 battlePower) {

    uint256 startId;
    uint256 endId;
    (startId, endId) = schema.battleCardIdRange();

    // Not ideal but will only be a small number of units (and saves gas when buying units)
    while (startId <= endId) {
      attackingPower = SafeMath.add(attackingPower,getUnitsAttack(player, startId, unitsOwned[player][startId]));
      stealingPower = SafeMath.add(stealingPower,getUnitsStealingCapacity(player, startId, unitsOwned[player][startId]));
      defendingPower = SafeMath.add(defendingPower,getUnitsDefense(player, startId, unitsOwned[player][startId]));
      battlePower = SafeMath.add(attackingPower,defendingPower); 
      startId++;
    }
  }

  // @nitice number of normal card
  function getOwnedCount(address player, uint256 cardId) external view returns (uint256) {
    return unitsOwned[player][cardId];
  }
  function setOwnedCount(address player, uint256 cardId, uint256 amount, bool iflag) external onlyAccess {
    if (iflag) {
      unitsOwned[player][cardId] = SafeMath.add(unitsOwned[player][cardId],amount);
     } else if (!iflag) {
      unitsOwned[player][cardId] = SafeMath.sub(unitsOwned[player][cardId],amount);
    }
  }

  // @notice Lv of upgrade card
  function getUpgradesOwned(address player, uint256 upgradeId) external view returns (uint256) {
    return upgradesOwned[player][upgradeId];
  }
  //set upgrade
  function setUpgradesOwned(address player, uint256 upgradeId) external onlyAccess {
    upgradesOwned[player][upgradeId] = SafeMath.add(upgradesOwned[player][upgradeId],1);
  }

  function getUintsOwnerCount(address _address) external view returns (uint256) {
    return uintsOwnerCount[_address];
  }
  function setUintsOwnerCount(address _address, uint256 amount, bool iflag) external onlyAccess {
    if (iflag) {
      uintsOwnerCount[_address] = SafeMath.add(uintsOwnerCount[_address],amount);
    } else if (!iflag) {
      uintsOwnerCount[_address] = SafeMath.sub(uintsOwnerCount[_address],amount);
    }
  }

  function getUnitCoinProductionIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitCoinProductionIncreases[_address][cardId];
  }

  function setUnitCoinProductionIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitCoinProductionIncreases[_address][cardId] = SafeMath.add(unitCoinProductionIncreases[_address][cardId],iValue);
    } else if (!iflag) {
      unitCoinProductionIncreases[_address][cardId] = SafeMath.sub(unitCoinProductionIncreases[_address][cardId],iValue);
    }
  }

  function getUnitCoinProductionMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitCoinProductionMultiplier[_address][cardId];
  }

  function setUnitCoinProductionMultiplier(address _address, uint256 cardId, uint256 iValue, bool iflag) external onlyAccess {
    if (iflag) {
      unitCoinProductionMultiplier[_address][cardId] = SafeMath.add(unitCoinProductionMultiplier[_address][cardId],iValue);
    } else if (!iflag) {
      unitCoinProductionMultiplier[_address][cardId] = SafeMath.sub(unitCoinProductionMultiplier[_address][cardId],iValue);
    }
  }

  function setUnitAttackIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitAttackIncreases[_address][cardId] = SafeMath.add(unitAttackIncreases[_address][cardId],iValue);
    } else if (!iflag) {
      unitAttackIncreases[_address][cardId] = SafeMath.sub(unitAttackIncreases[_address][cardId],iValue);
    }
  }

  function getUnitAttackIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitAttackIncreases[_address][cardId];
  } 
  function setUnitAttackMultiplier(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitAttackMultiplier[_address][cardId] = SafeMath.add(unitAttackMultiplier[_address][cardId],iValue);
    } else if (!iflag) {
      unitAttackMultiplier[_address][cardId] = SafeMath.sub(unitAttackMultiplier[_address][cardId],iValue);
    }
  }
  function getUnitAttackMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitAttackMultiplier[_address][cardId];
  } 

  function setUnitDefenseIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitDefenseIncreases[_address][cardId] = SafeMath.add(unitDefenseIncreases[_address][cardId],iValue);
    } else if (!iflag) {
      unitDefenseIncreases[_address][cardId] = SafeMath.sub(unitDefenseIncreases[_address][cardId],iValue);
    }
  }
  function getUnitDefenseIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitDefenseIncreases[_address][cardId];
  }
  function setunitDefenseMultiplier(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitDefenseMultiplier[_address][cardId] = SafeMath.add(unitDefenseMultiplier[_address][cardId],iValue);
    } else if (!iflag) {
      unitDefenseMultiplier[_address][cardId] = SafeMath.sub(unitDefenseMultiplier[_address][cardId],iValue);
    }
  }
  function getUnitDefenseMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitDefenseMultiplier[_address][cardId];
  }
  function setUnitJadeStealingIncreases(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitJadeStealingIncreases[_address][cardId] = SafeMath.add(unitJadeStealingIncreases[_address][cardId],iValue);
    } else if (!iflag) {
      unitJadeStealingIncreases[_address][cardId] = SafeMath.sub(unitJadeStealingIncreases[_address][cardId],iValue);
    }
  }
  function getUnitJadeStealingIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitJadeStealingIncreases[_address][cardId];
  } 

  function setUnitJadeStealingMultiplier(address _address, uint256 cardId, uint256 iValue,bool iflag) external onlyAccess {
    if (iflag) {
      unitJadeStealingMultiplier[_address][cardId] = SafeMath.add(unitJadeStealingMultiplier[_address][cardId],iValue);
    } else if (!iflag) {
      unitJadeStealingMultiplier[_address][cardId] = SafeMath.sub(unitJadeStealingMultiplier[_address][cardId],iValue);
    }
  }
  function getUnitJadeStealingMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitJadeStealingMultiplier[_address][cardId];
  } 

  function setUintCoinProduction(address _address, uint256 cardId, uint256 iValue, bool iflag) external onlyAccess {
    if (iflag) {
      uintProduction[_address][cardId] = SafeMath.add(uintProduction[_address][cardId],iValue);
     } else if (!iflag) {
      uintProduction[_address][cardId] = SafeMath.sub(uintProduction[_address][cardId],iValue);
    }
  }

  function getUintCoinProduction(address _address, uint256 cardId) external view returns (uint256) {
    return uintProduction[_address][cardId];
  }
}