pragma solidity ^0.4.18;
import "./CardsHelper.sol";

contract CardsRaffle is CardsHelper {

  // Raffle structures
  struct TicketPurchases {
    TicketPurchase[] ticketsBought;
    uint256 numPurchases; // Allows us to reset without clearing TicketPurchase[] (avoids potential for gas limit)
    uint256 raffleRareId;
  }
    
  // Allows us to query winner without looping (avoiding potential for gas limit)
  struct TicketPurchase {
    uint256 startId;
    uint256 endId;
  }
    
  // Raffle tickets
  mapping(address => TicketPurchases) private ticketsBoughtByPlayer;
  mapping(uint256 => address[]) private rafflePlayers; // Keeping a seperate list for each raffle has it's benefits. 

  uint256 private constant RAFFLE_TICKET_BASE_PRICE = 2000;

  // Current raffle info  
  uint256 private raffleEndTime;
  uint256 private raffleRareId;
  uint256 private raffleTicketsBought;
  address private raffleWinner; // Address of winner
  bool private raffleWinningTicketSelected;
  uint256 private raffleTicketThatWon;

  // Raffle for rare items  
  function buyRaffleTicket(uint256 amount) external {
    require(raffleEndTime >= block.timestamp);  //close it if need test
    require(amount > 0);
        
    uint256 ticketsCost = SafeMath.mul(RAFFLE_TICKET_BASE_PRICE, amount);
    require(cards.balanceOf(msg.sender) >= ticketsCost);
        
    // Update player's jade  
    cards.updatePlayersCoinByPurchase(msg.sender, ticketsCost);
        
    // Handle new tickets
    TicketPurchases storage purchases = ticketsBoughtByPlayer[msg.sender];
        
    // If we need to reset tickets from a previous raffle
    if (purchases.raffleRareId != raffleRareId) {
      purchases.numPurchases = 0;
      purchases.raffleRareId = raffleRareId;
      rafflePlayers[raffleRareId].push(msg.sender); // Add user to raffle
    }
        
    // Store new ticket purchase 
    if (purchases.numPurchases == purchases.ticketsBought.length) {
      purchases.ticketsBought.length = SafeMath.add(purchases.ticketsBought.length,1);
    }
    purchases.ticketsBought[purchases.numPurchases++] = TicketPurchase(raffleTicketsBought, raffleTicketsBought + (amount - 1)); // (eg: buy 10, get id's 0-9)
        
    // Finally update ticket total
    raffleTicketsBought = SafeMath.add(raffleTicketsBought,amount);
  } 

  /// @dev start raffle
  function startRareRaffle(uint256 endTime, uint256 rareId) external onlyOwner {
    require(rareId>0);
    require(rare.getRareItemsOwner(rareId) == getRareAddress());
    require(block.timestamp < endTime);

    if (raffleRareId != 0) { // Sanity to assure raffle has ended before next one starts
      require(raffleWinner != 0);
    }

    // Reset previous raffle info
    raffleWinningTicketSelected = false;
    raffleTicketThatWon = 0;
    raffleWinner = 0;
    raffleTicketsBought = 0;
        
    // Set current raffle info
    raffleEndTime = endTime;
    raffleRareId = rareId;
  }

  function awardRafflePrize(address checkWinner, uint256 checkIndex) external { 
    require(raffleEndTime < block.timestamp);  //close it if need test
    require(raffleWinner == 0);
    require(rare.getRareItemsOwner(raffleRareId) == getRareAddress());
        
    if (!raffleWinningTicketSelected) {
      drawRandomWinner(); // Ideally do it in one call (gas limit cautious)
    }
        
  // Reduce gas by (optionally) offering an address to _check_ for winner
    if (checkWinner != 0) {
      TicketPurchases storage tickets = ticketsBoughtByPlayer[checkWinner];
      if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.raffleRareId == raffleRareId) {
        TicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
        if (raffleTicketThatWon >= checkTicket.startId && raffleTicketThatWon <= checkTicket.endId) {
          assignRafflePrize(checkWinner); // WINNER!
          return;
        }
      }
    }
        
  // Otherwise just naively try to find the winner (will work until mass amounts of players)
    for (uint256 i = 0; i < rafflePlayers[raffleRareId].length; i++) {
      address player = rafflePlayers[raffleRareId][i];
      TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
            
      uint256 endIndex = playersTickets.numPurchases - 1;
      // Minor optimization to avoid checking every single player
      if (raffleTicketThatWon >= playersTickets.ticketsBought[0].startId && raffleTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
        for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
          TicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
          if (raffleTicketThatWon >= playerTicket.startId && raffleTicketThatWon <= playerTicket.endId) {
            assignRafflePrize(player); // WINNER!
            return;
            }
        }
      }
    }
  }

  function assignRafflePrize(address winner) internal {
    raffleWinner = winner;
    uint256 newPrice = (rare.rareStartPrice() * 25) / 20;
    rare.transferTokenByContract(raffleRareId,winner);
    rare.setRarePrice(raffleRareId,newPrice);
       
    cards.updatePlayersCoinByOut(winner);
    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    (,,,,upgradeClass, unitId, upgradeValue) = rare.getRareInfo(raffleRareId);
    
    upgradeUnitMultipliers(winner, upgradeClass, unitId, upgradeValue);
  }
  
  // Random enough for small contests (Owner only to prevent trial & error execution)
  function drawRandomWinner() public {
    require(msg.sender == owner);
    require(raffleEndTime < block.timestamp); //close it if need to test
    require(!raffleWinningTicketSelected);
        
    uint256 seed = SafeMath.add(raffleTicketsBought , block.timestamp);
    raffleTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, raffleTicketsBought);
    raffleWinningTicketSelected = true;
  }  

  // To allow clients to verify contestants
  function getRafflePlayers(uint256 raffleId) external constant returns (address[]) {
    return (rafflePlayers[raffleId]);
  }

    // To allow clients to verify contestants
  function getPlayersTickets(address player) external constant returns (uint256[], uint256[]) {
    TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
        
    if (playersTickets.raffleRareId == raffleRareId) {
      uint256[] memory startIds = new uint256[](playersTickets.numPurchases);
      uint256[] memory endIds = new uint256[](playersTickets.numPurchases);
            
      for (uint256 i = 0; i < playersTickets.numPurchases; i++) {
        startIds[i] = playersTickets.ticketsBought[i].startId;
        endIds[i] = playersTickets.ticketsBought[i].endId;
      }
    }
        
    return (startIds, endIds);
  }


  // To display on website
  function getLatestRaffleInfo() external constant returns (uint256, uint256, uint256, address, uint256) {
    return (raffleEndTime, raffleRareId, raffleTicketsBought, raffleWinner, raffleTicketThatWon);
  }    
}