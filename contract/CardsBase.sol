pragma solidity ^0.4.18;
import "./GameConfigInterface.sol";
import "./JadeCoin.sol";

/// @notice 卡牌基础数据合约，获取卡牌的数值
/// @author rainysiu rainy@livestar.com
/// @dev MagicAcademy Games 

contract CardsBase is JadeCoin {

  function CardsBase() public {
  } 
  // player  
  struct Player {
    address owneraddress;
  }

  Player[] players;

  bool gameStarted;
  GameConfigInterface public schema;

  // Stuff owned by each player
  mapping(address => mapping(uint256 => uint256)) public unitsOwned;  //用户的普通卡牌的数量
  mapping(address => mapping(uint256 => uint256)) public upgradesOwned;  //用户拥有的的升级卡牌
  mapping(uint256 => address) public rareItemOwner; // 拥有稀有卡牌的用户
  mapping(uint256 => uint256) public rareItemPrice; // 稀有卡牌的价格
  mapping(address => uint256) public uintsOwnerCount; // 用户拥有的卡牌数量

  // Rares & Upgrades (Increase unit's production / attack etc.)
  mapping(address => mapping(uint256 => uint256)) public unitCoinProductionIncreases; // Adds to the coin per second
  mapping(address => mapping(uint256 => uint256)) public unitCoinProductionMultiplier; // Multiplies the coin per second
  mapping(address => mapping(uint256 => uint256)) public unitAttackIncreases;
  mapping(address => mapping(uint256 => uint256)) public unitAttackMultiplier;
  mapping(address => mapping(uint256 => uint256)) public unitDefenseIncreases;
  mapping(address => mapping(uint256 => uint256)) public unitDefenseMultiplier;
  mapping(address => mapping(uint256 => uint256)) public unitJadeStealingIncreases;
  mapping(address => mapping(uint256 => uint256)) public unitJadeStealingMultiplier;

  mapping(address=> mapping(uint256 => uint256)) public uintCoinProduction;  //某张卡牌的总产量
  
  //设置游戏参数
  function setConfigAddress(address _address) external onlyOwner {
    schema = GameConfigInterface(_address);
  }

    /// 启动游戏，只有合约的拥有者可以启动
  function beginGame(uint256 firstDivsTime) external payable onlyOwner {
    require(!gameStarted);
    gameStarted = true; // GO-OOOO!
    nextSnapshotTime = firstDivsTime;
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
  /// @notice  获取玩家列表
  /// @author rainysiu
  function getPlayers() public view returns (address[]) {
    uint256 len = players.length;

    address[] memory result = new address[](len);
    uint counter = 0;
    for (uint i = 0; i<len; i++) {
      result[counter] = players[i].owneraddress;  
      counter++;
    }
    return result;
  }
  /// @notice 获取玩家产量列表
  /// @author rainysiu
  function getPlayersPro() private view returns (uint256[]) {
    uint256 len = players.length;
    uint256[] memory result = new uint256[](len);
    /** 返回玩家产量数组**/
    uint counter = 0;

    for (uint i=0;i<len; i++){
      result[counter] = balanceOf(players[i].owneraddress);
      counter++;
    }
    return result;
  } 

  /// @notice 获取玩家产量排行榜
  /// @notice rainysiu
  function getRanking() external view returns (address[] addr, uint256[] _arr) {
    uint256 len = players.length;
    uint256[] memory arr = new uint256[](len);
    address[] memory arr_addr = new address[](len);
    addr = new address[](len);

    arr = getPlayersPro();
    arr_addr = getPlayers();
    // 冒泡算法排序
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
    _arr = arr; 
    addr = arr_addr;
  }
  //获取玩家总数
  function getTotalUsers()  external view returns (uint256) {
    return players.length;
  }
  
  /// 获取卡牌产量
  function getUnitsProduction(address player, uint256 unitId, uint256 amount) external constant returns (uint256) {
    return (amount * (schema.unitCoinProduction(unitId) + unitCoinProductionIncreases[player][unitId]) * (10 + unitCoinProductionMultiplier[player][unitId])) / 10; 
  } 

  /// 获取卡牌单张的产量
  function getUnitsInProduction(address player, uint256 unitId, uint256 amount) external constant returns (uint256) {
    return SafeMath.div(SafeMath.mul(amount,uintCoinProduction[player][unitId]),unitsOwned[player][unitId]);
  } 

  /// 获取卡牌的攻击能力
  function getUnitsAttack(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
    return (amount * (schema.unitAttack(unitId) + unitAttackIncreases[player][unitId]) * (10 + unitAttackMultiplier[player][unitId])) / 10;
  }
  /// 获取卡牌的防御能力
  function getUnitsDefense(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
    return (amount * (schema.unitDefense(unitId) + unitDefenseIncreases[player][unitId]) * (10 + unitDefenseMultiplier[player][unitId])) / 10;
  }
  /// 获取卡牌的偷窃能力
  function getUnitsStealingCapacity(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
    return (amount * (schema.unitStealingCapacity(unitId) + unitJadeStealingIncreases[player][unitId]) * (10 + unitJadeStealingMultiplier[player][unitId])) / 10;
  }
 
  // 计算攻击者 和 防御者的 战力
  function getPlayersBattlePower(address attacker, address defender) external constant returns (
    uint256 attackingPower, 
    uint256 defendingPower, 
    uint256 stealingPower) {
    
    uint256 startId;
    uint256 endId;
    (startId, endId) = schema.battleCardIdRange();
    
    // Not ideal but will only be a small number of units (and saves gas when buying units)
    while (startId <= endId) {
      attackingPower = SafeMath.add(attackingPower,getUnitsAttack(attacker, startId, unitsOwned[attacker][startId])); //计算攻击者的攻击力
      stealingPower = SafeMath.add(stealingPower,getUnitsStealingCapacity(attacker, startId, unitsOwned[attacker][startId]));  //计算攻击者的偷窃能力  
      defendingPower = SafeMath.add(defendingPower,getUnitsDefense(defender, startId, unitsOwned[defender][startId])); //计算防御者的防御能力
      startId++;
      }
    //return (attackingPower, defendingPower, stealingPower);
  }

  // New units may be added in future, but check it matches existing schema so no-one can abuse selling.

  function updateGameConfig(address newSchemaAddress) external onlyOwner {     
    GameConfigInterface newSchema = GameConfigInterface(newSchemaAddress);
    requireExistingUnitsSame(newSchema);
    requireExistingUpgradesSame(newSchema);
        
    // Finally update config
    schema = GameConfigInterface(newSchema);
  }
  /// 要求新的配置和旧的配置吻合
  function requireExistingUnitsSame(GameConfigInterface newSchema) internal constant {
    // Requires units eth costs match up or fail execution
        
    uint256 startId;
    uint256 endId;
    (startId, endId) = schema.productionCardIdRange();
    while (startId <= endId) {
      require(schema.unitEthCost(startId) == newSchema.unitEthCost(startId));
      require(schema.unitCoinProduction(startId) == newSchema.unitCoinProduction(startId));
      startId++;
    }
        
    (startId, endId) = schema.battleCardIdRange();
    while (startId <= endId) {
      require(schema.unitEthCost(startId) == newSchema.unitEthCost(startId));
      require(schema.unitAttack(startId) == newSchema.unitAttack(startId));
      require(schema.unitDefense(startId) == newSchema.unitDefense(startId));
      require(schema.unitStealingCapacity(startId) == newSchema.unitStealingCapacity(startId));
      startId++;
    }
  }

  /// 要求新的配置和旧的配置吻合  
  function requireExistingUpgradesSame(GameConfigInterface newSchema) internal constant {
    uint256 startId;
    uint256 endId;
        
    uint256 oldClass;
    uint256 oldUnitId;
    uint256 oldValue;
        
    uint256 newClass;
    uint256 newUnitId;
    uint256 newValue;
        
    // Requires ALL upgrade stats match up or fail execution
    (startId, endId) = schema.rareIdRange();
    while (startId <= endId) {
      uint256 oldCoinCost;
      uint256 oldEthCost;
      (oldCoinCost, oldEthCost, oldClass, oldUnitId, oldValue) = schema.getUpgradeInfo(startId);
            
      uint256 newCoinCost;
      uint256 newEthCost;
      (newCoinCost, newEthCost, newClass, newUnitId, newValue) = newSchema.getUpgradeInfo(startId);
            
      require(oldCoinCost == newCoinCost);
      require(oldEthCost == oldEthCost);
      require(oldClass == oldClass);
      require(oldUnitId == newUnitId);
      require(oldValue == newValue);
      startId++;
      }
        
      // Requires ALL rare stats match up or fail execution
    (startId, endId) = schema.rareIdRange();
    while (startId <= endId) {
      (oldClass, oldUnitId, oldValue) = schema.getRareInfo(startId);
      (newClass, newUnitId, newValue) = newSchema.getRareInfo(startId);
            
      require(oldClass == newClass);
      require(oldUnitId == newUnitId);
      require(oldValue == newValue);
      startId++;
      }
  }

    /// 获取玩家的战斗属性：攻击、防御、偷窃 display in website
  function getPlayersBattleStats(address player) external constant returns (
    uint256 attackingPower, 
    uint256 defendingPower, 
    uint256 stealingPower) {

    uint256 startId;
    uint256 endId;
    (startId, endId) = schema.battleCardIdRange();

    // Not ideal but will only be a small number of units (and saves gas when buying units)
    while (startId <= endId) {
      attackingPower = SafeMath.add(attackingPower,getUnitsAttack(player, startId, unitsOwned[player][startId]));
      stealingPower = SafeMath.add(stealingPower,getUnitsStealingCapacity(player, startId, unitsOwned[player][startId]));
      defendingPower = SafeMath.add(defendingPower,getUnitsDefense(player, startId, unitsOwned[player][startId]));
      startId++;
    }
  }
  // @nitice 获取某张普通卡牌的数量
  function getOwnedCount(address player, uint256 cardId) external view returns (uint256) {
    return unitsOwned[player][cardId];
  }
    // @nitice 获取某张普通卡牌的数量
  function setOwnedCount(address player, uint256 cardId, uint256 amount , string flag) external onlyAccess {
    if (keccak256(flag) == keccak256("add")) {
      unitsOwned[player][cardId] = SafeMath.add(unitsOwned[player][cardId],amount);
    } else if (keccak256(flag) == keccak256("sub")) {
      unitsOwned[player][cardId] = SafeMath.sub(unitsOwned[player][cardId],amount);
    }
  }

  // @notice 拥有的升级卡牌的等级
  function getUpgradesOwned(address player, uint256 upgradeId) external view returns (uint256) {
    return upgradesOwned[player][upgradeId];
  }

  function setUpgradesOwned(address player, uint256 upgradeId) external onlyAccess {
    upgradesOwned[player][upgradeId] = SafeMath.add(upgradesOwned[player][upgradeId],1);
  }

  function getRareItemsOwner(uint256 rareId) public view returns (address) {
    return rareItemOwner[rareId];
  }
  
  function getRareItemsPrice(uint256 rareId) public view returns (uint256) {
    return rareItemPrice[rareId];
  }

  function setRareOwner(uint256 _rareId, address _address) external onlyAccess {
    rareItemOwner[_rareId] = _address;
  }

  function setRarePrice(uint256 _rareId, uint256 _price) external onlyAccess {
    rareItemPrice[_rareId] = _price;
  }

  function getUintsOwnerCount(address _address) external view returns (uint256) {
    return uintsOwnerCount[_address];
  }
  function setUintsOwnerCount(address _address, uint256 amount, string flag) external onlyAccess {
    if (keccak256(flag) == keccak256("add")) {
      uintsOwnerCount[_address] = SafeMath.add(uintsOwnerCount[_address],amount);
    } else if (keccak256(flag) == keccak256("sub")) {
      uintsOwnerCount[_address] = SafeMath.sub(uintsOwnerCount[_address],amount);
    }
  }

  function getUnitCoinProductionIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitCoinProductionIncreases[_address][cardId];
  }

  //产品加权
  function setUnitCoinProductionIncreases(address _address, uint256 cardId, uint256 iValue,string flag) external onlyAccess {
    if (keccak256(flag) == keccak256("add")) {
      unitCoinProductionIncreases[_address][cardId] = SafeMath.add(unitCoinProductionIncreases[_address][cardId],iValue);
    } else if (keccak256(flag) == keccak256("sub")) {
      unitCoinProductionIncreases[_address][cardId] = SafeMath.sub(unitCoinProductionIncreases[_address][cardId],iValue);
    }
  }

  function getUnitCoinProductionMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitCoinProductionMultiplier[_address][cardId];
  }

  function setUnitCoinProductionMultiplier(address _address, uint256 cardId, uint256 iValue,string flag) external onlyAccess {
    if (keccak256(flag) == keccak256("add")) {
      unitCoinProductionMultiplier[_address][cardId] = SafeMath.add(unitCoinProductionMultiplier[_address][cardId],iValue);
    } else if (keccak256(flag) == keccak256("sub")) {
      unitCoinProductionMultiplier[_address][cardId] = SafeMath.sub(unitCoinProductionMultiplier[_address][cardId],iValue);
    }
  }

  function setUnitAttackIncreases(address _address, uint256 cardId, uint256 iValue,string flag) external onlyAccess {
    if (keccak256(flag) == keccak256("add")) {
      unitAttackIncreases[_address][cardId] = SafeMath.add(unitAttackIncreases[_address][cardId],iValue);
    } else if (keccak256(flag) == keccak256("sub")) {
      unitAttackIncreases[_address][cardId] = SafeMath.sub(unitAttackIncreases[_address][cardId],iValue);
    }
  }
  function getUnitAttackIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitAttackIncreases[_address][cardId];
  } 
  function setUnitAttackMultiplier(address _address, uint256 cardId, uint256 iValue,string flag) external onlyAccess {
    if (keccak256(flag) == keccak256("add")) {
      unitAttackMultiplier[_address][cardId] = SafeMath.add(unitAttackMultiplier[_address][cardId],iValue);
    } else if (keccak256(flag) == keccak256("sub")) {
      unitAttackMultiplier[_address][cardId] = SafeMath.sub(unitAttackMultiplier[_address][cardId],iValue);
    }
  }
  function getUnitAttackMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitAttackMultiplier[_address][cardId];
  } 

  function setUnitDefenseIncreases(address _address, uint256 cardId, uint256 iValue,string flag) external onlyAccess {
    if (keccak256(flag) == keccak256("add")) {
      unitDefenseIncreases[_address][cardId] = SafeMath.add(unitDefenseIncreases[_address][cardId],iValue);
    } else if (keccak256(flag) == keccak256("sub")) {
      unitDefenseIncreases[_address][cardId] = SafeMath.sub(unitDefenseIncreases[_address][cardId],iValue);
    }
  }
  function getUnitDefenseIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitDefenseIncreases[_address][cardId];
  } 
  function setunitDefenseMultiplier(address _address, uint256 cardId, uint256 iValue,string flag) external onlyAccess {
    if (keccak256(flag) == keccak256("add")) {
      unitDefenseMultiplier[_address][cardId] = SafeMath.add(unitDefenseMultiplier[_address][cardId],iValue);
    } else if (keccak256(flag) == keccak256("sub")) {
      unitDefenseMultiplier[_address][cardId] = SafeMath.sub(unitDefenseMultiplier[_address][cardId],iValue);
    }
  }
  function getUnitDefenseMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitDefenseMultiplier[_address][cardId];
  } 
  function setUnitJadeStealingIncreases(address _address, uint256 cardId, uint256 iValue,string flag) external onlyAccess {
    if (keccak256(flag) == keccak256("add")) {
      unitJadeStealingIncreases[_address][cardId] = SafeMath.add(unitJadeStealingIncreases[_address][cardId],iValue);
    } else if (keccak256(flag) == keccak256("sub")) {
      unitJadeStealingIncreases[_address][cardId] = SafeMath.sub(unitJadeStealingIncreases[_address][cardId],iValue);
    }
  }
  function getUnitJadeStealingIncreases(address _address, uint256 cardId) external view returns (uint256) {
    return unitJadeStealingIncreases[_address][cardId];
  } 

  function setUnitJadeStealingMultiplier(address _address, uint256 cardId, uint256 iValue,string flag) external onlyAccess {
    if (keccak256(flag) == keccak256("add")) {
      unitJadeStealingMultiplier[_address][cardId] = SafeMath.add(unitJadeStealingMultiplier[_address][cardId],iValue);
    } else if (keccak256(flag) == keccak256("sub")) {
      unitJadeStealingMultiplier[_address][cardId] = SafeMath.sub(unitJadeStealingMultiplier[_address][cardId],iValue);
    }
  }
  function getUnitJadeStealingMultiplier(address _address, uint256 cardId) external view returns (uint256) {
    return unitJadeStealingMultiplier[_address][cardId];
  } 
  function setUintCoinProduction(address _address, uint256 cardId, uint256 iValue,string flag) external onlyAccess {
    if (keccak256(flag) == keccak256("add")) {
      uintCoinProduction[_address][cardId] = SafeMath.add(uintCoinProduction[_address][cardId],iValue);
     } else if (keccak256(flag) == keccak256("sub")) {
      uintCoinProduction[_address][cardId] = SafeMath.sub(uintCoinProduction[_address][cardId],iValue);
    }
  }

  function getUintCoinProduction(address _address, uint256 cardId) external view returns (uint256) {
    return uintCoinProduction[_address][cardId];
  }
}