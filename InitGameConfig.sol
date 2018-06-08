pragma solidity ^0.4.18;

interface GameInterface {
  function CreateBattleCards(uint256 _cardId, uint256 _baseCoinCost, uint256 _coinCostIncreaseHalf, uint256 _ethCost, uint _attackValue, uint256 _defenseValue, uint256 _coinStealingCapacity, bool _unitSellable) external;
  function CreateCards(uint256 _cardId, uint256 _baseCoinCost, uint256 _coinCostIncreaseHalf, uint256 _ethCost, uint256 _baseCoinProduction, bool _unitSellable) external;
  function CreateUpgradeCards(uint256 _upgradecardId, uint256 _coinCost, uint256 _ethCost, uint256 _upgradeClass, uint256 _cardId, uint256 _upgradeValue, uint256 _increase) external;
}

contract InitGameConfig {

  address owner;
  GameInterface public schema;

  function InitGameConfig() public {
    owner = msg.sender;
  }

  //setting configuration
  function setConfigAddress(address _address) external onlyOwner {
    schema = GameInterface(_address);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function InitCardConfig() external onlyOwner {
    schema.CreateCards(1, 0, 10, 0, 2,  true);          
    schema.CreateCards(2, 100, 50, 0, 5,  true);           
    schema.CreateCards(3, 0, 0, 0.01 ether, 100, true);    
    schema.CreateCards(4, 200, 100, 0, 10,  true);          
    schema.CreateCards(5, 500, 250, 0, 20,  true);        
    schema.CreateCards(6, 1000, 500, 0, 40,  true);       
    schema.CreateCards(7, 0, 1000, 0.05 ether, 500,  true); 
    schema.CreateCards(8, 1500, 750, 0, 60,  true);
    schema.CreateCards(9, 0, 0, 0.99 ether, 5500, false);     
  }  

  function InitBattleCardConfig() external onlyOwner {
    //attack
    schema.CreateBattleCards(40, 50, 25, 0,  10, 10, 10000, true);    //50    
    schema.CreateBattleCards(41, 100, 50, 0,  5, 25, 500, true);     //100    
    schema.CreateBattleCards(42, 0, 0, 0.01 ether,  200, 10, 50000, true); //0.01
    schema.CreateBattleCards(43, 250, 125, 0, 25, 5, 15000, true);       // 250
    schema.CreateBattleCards(44, 500, 250, 0, 20, 40, 5000, true);     //500
    schema.CreateBattleCards(45, 0, 2500, 0.02 ether, 0, 0, 100000, true);  //0.02
    schema.CreateBattleCards(46, 0, 0, 0.005 ether, 100, 10, 50000, true);  //0.005
    schema.CreateBattleCards(47, 0, 0, 0.03 ether, 250, 80, 100000, true);  //0.03
  } 

  function InitUpgradeCard() external onlyOwner {
  //upgradecardId,coinCost,ethCost,upgradeClass,cardId,upgradeValue,increase;
    schema.CreateUpgradeCards(1 ,2500,0 ,0,1,1,50);      
    schema.CreateUpgradeCards(2 ,0,0.05 ether,1,1,1,100); 
    schema.CreateUpgradeCards(3 ,5000,0 ,0,1,2,150);

    schema.CreateUpgradeCards(4,0,0.1 ether,1,2,1,100);  
    schema.CreateUpgradeCards(5,12500,0,0,2,2,150);
    schema.CreateUpgradeCards(6,0,0.2 ether,1,2,2,100);  

    schema.CreateUpgradeCards(7,25000,0,0,3,5,300);
    schema.CreateUpgradeCards(8,0,0.5 ether,1,3,4,100);
    schema.CreateUpgradeCards(9,25000,0,1,3,1,50);  

    schema.CreateUpgradeCards(10,0,0.1 ether,1,4,2,100);
    schema.CreateUpgradeCards(11,37500,0,0,4,4,100);
    schema.CreateUpgradeCards(12,0,0.2 ether,1,4,4,100);

    schema.CreateUpgradeCards(13,75000,0,0,5,6,300);
    schema.CreateUpgradeCards(14,0,0.5 ether,1,5,4,100);
    schema.CreateUpgradeCards(15,100000,0,1,5,5,50);  

    schema.CreateUpgradeCards(16,0,0.1 ether,1,6,2,100);
    schema.CreateUpgradeCards(17,125000,0,0,6	,8,50);
    schema.CreateUpgradeCards(18,0,0.2 ether,1,6,4,100);

    schema.CreateUpgradeCards(19,175000,0,0,7,25,50);
    schema.CreateUpgradeCards(20,0,0.2 ether,1,7,2,100);
    schema.CreateUpgradeCards(21,200000,0,1,7,5,50);  //class =1

    schema.CreateUpgradeCards(22,0,0.1 ether,1,8,2,100);
    schema.CreateUpgradeCards(23,250000,0,0,8,10,50);
    schema.CreateUpgradeCards(24,0,0.2 ether,1,8,4,100);

    //for battle cards
    schema.CreateUpgradeCards(25,10000,0,2,40,5,10);
    schema.CreateUpgradeCards(26,0,0.1 ether,4,40,20,100); 
    schema.CreateUpgradeCards(27,12500,0,6,40,2000,10);

    schema.CreateUpgradeCards(28,0,0.1 ether,3,41,10,100); // 5 -> 10
    schema.CreateUpgradeCards(29,25000,0,4,41	,5,10);
    schema.CreateUpgradeCards(30,0,0.2 ether,6,41,10000,100);  

    schema.CreateUpgradeCards(31,25000,0,4,42	,5,10);
    schema.CreateUpgradeCards(32,0,0.2 ether,6,42,15000,100);
    schema.CreateUpgradeCards(33,37500,0,2,42	,5,10);

    schema.CreateUpgradeCards(34,0,0.2 ether,5,43,10,100);
    schema.CreateUpgradeCards(35,125000,0,2,43,5,10);
    schema.CreateUpgradeCards(36,0,0.5 ether,3,43,20,100);

    schema.CreateUpgradeCards(37,0,0.2 ether,3,44,10,100);
    schema.CreateUpgradeCards(38,150000,0,4,44,5,10);
    schema.CreateUpgradeCards(39,0,0.5 ether,5,44,20,100);

    schema.CreateUpgradeCards(40,100000,0,6,45,10000,10);
    schema.CreateUpgradeCards(41,0,0.5 ether,7,45,10,100);
    schema.CreateUpgradeCards(42,150000,0,7,45,5,10);

    schema.CreateUpgradeCards(43,75000,0,3,46	,5,10);
    schema.CreateUpgradeCards(44,0,0.5 ether,4,46,60,100);
    schema.CreateUpgradeCards(45,125000,0,7,46,5,10);
    
    schema.CreateUpgradeCards(46,0,0.2 ether,6,47,20000,100);
    schema.CreateUpgradeCards(47,125000,0,5,47,10,10);
    schema.CreateUpgradeCards(48,0,0.5 ether,2,47,200,10);
    
  } 
}