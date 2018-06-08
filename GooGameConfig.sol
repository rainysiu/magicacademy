pragma solidity ^0.4.18;
contract GooGameConfig {
    
    mapping(uint256 => Unit) private unitInfo;
    mapping(uint256 => Upgrade) private upgradeInfo;
    mapping(uint256 => Rare) private rareInfo;
    
    uint256 public constant currentNumberOfUnits = 15;
    uint256 public constant currentNumberOfUpgrades = 210;
    uint256 public constant currentNumberOfRares = 2;
    
    address public owner;
    
    struct Unit {
        uint256 unitId;
        uint256 baseGooCost;
        uint256 gooCostIncreaseHalf; // Halfed to make maths slightly less (cancels a 2 out)
        uint256 ethCost;
        uint256 baseGooProduction;
        
        uint256 attackValue;
        uint256 defenseValue;
        uint256 gooStealingCapacity;
        bool unitSellable; // Rare units (from raffle) not sellable
    }
    
    struct Upgrade {
        uint256 upgradeId;
        uint256 gooCost;
        uint256 ethCost;
        uint256 upgradeClass;
        uint256 unitId;
        uint256 upgradeValue;
        uint256 prerequisiteUpgrade;
    }
    
    struct Rare {
        uint256 rareId;
        uint256 ethCost;
        uint256 rareClass;
        uint256 unitId;
        uint256 rareValue;
    }
    
    function GooGameConfig() public {
        owner = msg.sender;
        
        rareInfo[1] = Rare(1, 0.5 ether, 1, 1, 40); // 40 = +400%
        rareInfo[2] = Rare(2, 0.5 ether, 0, 2, 35); // +35
        
        unitInfo[1] = Unit(1, 0, 10, 0, 2, 0, 0, 0, true);
        unitInfo[2] = Unit(2, 100, 50, 0, 5, 0, 0, 0, true);
        unitInfo[3] = Unit(3, 0, 0, 0.01 ether, 100, 0, 0, 0, true);
        unitInfo[4] = Unit(4, 200, 100, 0, 10, 0, 0, 0, true);
        unitInfo[5] = Unit(5, 500, 250, 0, 20, 0, 0, 0, true);
        unitInfo[6] = Unit(6, 1000, 500, 0, 40, 0, 0, 0, true);
        unitInfo[7] = Unit(7, 0, 1000, 0.05 ether, 500, 0, 0, 0, true);
        unitInfo[8] = Unit(8, 1500, 750, 0, 60, 0, 0, 0, true);
        unitInfo[9] = Unit(9, 0, 0, 10 ether, 6000, 0, 0, 0, false); // First secret rare unit from raffle (unsellable)
        
        unitInfo[40] = Unit(40, 50, 25, 0, 0, 10, 10, 10000, true);
        unitInfo[41] = Unit(41, 100, 50, 0, 0, 1, 25, 500, true);
        unitInfo[42] = Unit(42, 0, 0, 0.01 ether, 0, 200, 10, 50000, true);
        unitInfo[43] = Unit(43, 250, 125, 0, 0, 25, 1, 15000, true);
        unitInfo[44] = Unit(44, 500, 250, 0, 0, 20, 40, 5000, true);
        unitInfo[45] = Unit(45, 0, 2500, 0.02 ether, 0, 0, 0, 100000, true);
    }
    
    address allowedConfig;
    function setConfigSetupContract(address schema) external {
        require(msg.sender == owner);
        allowedConfig = schema;
    }
    
    function addUpgrade(uint256 id, uint256 goo, uint256 eth, uint256 class, uint256 unit, uint256 value, uint256 prereq) external {
        require(msg.sender == allowedConfig);
        upgradeInfo[id] = Upgrade(id, goo, eth, class, unit, value, prereq);
    }
    
    function getGooCostForUnit(uint256 unitId, uint256 existing, uint256 amount) public constant returns (uint256) {
        Unit storage unit = unitInfo[unitId];
        if (amount == 1) { // 1
            if (existing == 0) {
                return unit.baseGooCost;
            } else {
                return unit.baseGooCost + (existing * unit.gooCostIncreaseHalf * 2);
            }
        } else if (amount > 1) {
            uint256 existingCost;
            if (existing > 0) { // Gated by unit limit
                existingCost = (unit.baseGooCost * existing) + (existing * (existing - 1) * unit.gooCostIncreaseHalf);
            }
            
            existing = SafeMath.add(existing, amount);
            return SafeMath.add(SafeMath.mul(unit.baseGooCost, existing), SafeMath.mul(SafeMath.mul(existing, (existing - 1)), unit.gooCostIncreaseHalf)) - existingCost;
        }
    }
    
    function getWeakenedDefensePower(uint256 defendingPower) external constant returns (uint256) {
        return defendingPower / 2;
    }
    
    function validRareId(uint256 rareId) external constant returns (bool) {
        return (rareId > 0 && rareId < 3);
    }
    
    function unitSellable(uint256 unitId) external constant returns (bool) {
        return unitInfo[unitId].unitSellable;
    }
    
    function unitEthCost(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].ethCost;
    }
    
    function unitGooProduction(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].baseGooProduction;
    }
    
    function unitAttack(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].attackValue;
    }
    
    function unitDefense(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].defenseValue;
    }
    
    function unitStealingCapacity(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].gooStealingCapacity;
    }
    
    function rareStartPrice(uint256 rareId) external constant returns (uint256) {
        return rareInfo[rareId].ethCost;
    }
    
    function upgradeGooCost(uint256 upgradeId) external constant returns (uint256) {
        return upgradeInfo[upgradeId].gooCost;
    }
    
    function upgradeEthCost(uint256 upgradeId) external constant returns (uint256) {
        return upgradeInfo[upgradeId].ethCost;
    }
    
    function upgradeClass(uint256 upgradeId) external constant returns (uint256) {
        return upgradeInfo[upgradeId].upgradeClass;
    }
    
    function upgradeUnitId(uint256 upgradeId) external constant returns (uint256) {
        return upgradeInfo[upgradeId].unitId;
    }
    
    function upgradeValue(uint256 upgradeId) external constant returns (uint256) {
        return upgradeInfo[upgradeId].upgradeValue;
    }
    
    function productionUnitIdRange() external constant returns (uint256, uint256) {
        return (1, 9);
    }
    
    function battleUnitIdRange() external constant returns (uint256, uint256) {
        return (40, 45);
    }
    
    function upgradeIdRange() external constant returns (uint256, uint256) {
        return (1, 210);
    }
    
    function rareIdRange() external constant returns (uint256, uint256) {
        return (1, 2);
    }
    
    function getUpgradeInfo(uint256 upgradeId) external constant returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (upgradeInfo[upgradeId].gooCost, upgradeInfo[upgradeId].ethCost, upgradeInfo[upgradeId].upgradeClass,
        upgradeInfo[upgradeId].unitId, upgradeInfo[upgradeId].upgradeValue, upgradeInfo[upgradeId].prerequisiteUpgrade);
    }
    
    function getRareInfo(uint256 rareId) external constant returns (uint256, uint256, uint256) {
        return (rareInfo[rareId].rareClass, rareInfo[rareId].unitId, rareInfo[rareId].rareValue);
    }
    
    function getUnitInfo(uint256 unitId, uint256 existing, uint256 amount) external constant returns (uint256, uint256, uint256, uint256) {
        return (unitInfo[unitId].unitId, unitInfo[unitId].baseGooProduction, getGooCostForUnit(unitId, existing, amount), SafeMath.mul(unitInfo[unitId].ethCost, amount));
    }
    
}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}