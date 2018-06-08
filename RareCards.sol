pragma solidity ^0.4.18;
import "./RareAccess.sol";
import "./ERC721.sol";
import "./SafeMath.sol";

contract RareCards is RareAccess, ERC721 {
  using SafeMath for SafeMath;
  // event
  event eCreateRare(uint256 tokenId, uint256 price, address owner);

  // ERC721
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  struct RareCard {
    uint256 rareId;     // rare item id
    uint256 rareClass;  // upgrade level of rare item
    uint256 cardId;     // related to basic card ID 
    uint256 rareValue;  // upgrade value of rare item
  }

  RareCard[] public rareArray; // dynamic Array

  function RareCards() public {
    rareArray.length += 1;
  }

  /*** CONSTRUCTOR ***/
  uint256 private constant PROMO_CREATION_LIMIT = 20;
  uint256 private constant startPrice = 0.5 ether;

  uint256 public promoCreatedCount;
  address thisAddress = this;

  /**mapping**/
  /// @dev map tokenId to owner (tokenId -> address)
  mapping (uint256 => address) public IndexToOwner;
  /// @dev search rare item index in owner's array (tokenId -> index)
  mapping (uint256 => uint256) indexOfOwnedToken;
  /// @dev list of owned rare items by owner
  mapping (address => uint256[]) ownerToRareArray;
  /// @dev search token price by tokenId
  mapping (uint256 => uint256) IndexToPrice;
  /// @dev get the authorized address for each rare item
  mapping (uint256 => address) public IndexToApproved;
  /// @dev get the authorized operators for each rare item
  mapping (address => mapping(address => bool)) operatorToApprovals;



  /** Modifier **/
  /// @dev Check if token ID is valid
  modifier isValidToken(uint256 _tokenId) {
    require(_tokenId >= 1 && _tokenId <= rareArray.length);
    require(IndexToOwner[_tokenId] != address(0)); 
    _;
  }
  /// @dev check the ownership of token
  modifier onlyOwnerOf(uint _tokenId) {
    require(msg.sender == IndexToOwner[_tokenId] || msg.sender == IndexToApproved[_tokenId]);
    _;
  }

  /// @dev create a new rare item
  function createRareCard(uint256 _rareClass, uint256 _cardId, uint256 _rareValue) public onlyOwner {
    require(promoCreatedCount < PROMO_CREATION_LIMIT); 
    _createRareCard(thisAddress, startPrice, _rareClass, _cardId, _rareValue);
    promoCreatedCount = SafeMath.add(promoCreatedCount,1);
  }


  /// steps to create rare item 
  function _createRareCard(address _owner, uint256 _price, uint256 _rareClass, uint256 _cardId, uint256 _rareValue) internal returns(uint) {
    uint256 newTokenId = rareArray.length;
    //rareArray.length += 1;
    RareCard memory _rarecard = RareCard({
      rareId: newTokenId,
      rareClass: _rareClass,
      cardId: _cardId,
      rareValue: _rareValue
    });
    rareArray.push(_rarecard);
    //rareInfo[newTokenId] = _rarecard;

    //event
    eCreateRare(newTokenId, _price, _owner);

    IndexToPrice[newTokenId] = _price;
    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newTokenId);

    return newTokenId;
  } 

  /// @dev transfer the ownership of tokenId
  /// @param _from The old owner of rare item(If created: 0x0)
  /// @param _to The new owner of rare item
  /// @param _tokenId The tokenId of rare item
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    if (_from != address(0)) {
      uint256 indexFrom = indexOfOwnedToken[_tokenId];
      uint256[] storage rareArrayOfOwner = ownerToRareArray[_from];
      require(rareArrayOfOwner[indexFrom] == _tokenId);

      // Switch the positions of selected item and last item
      if (indexFrom != rareArrayOfOwner.length - 1) {
        uint256 lastTokenId = rareArrayOfOwner[rareArrayOfOwner.length - 1];
        rareArrayOfOwner[indexFrom] = lastTokenId;
        indexOfOwnedToken[lastTokenId] = indexFrom;
      }
      rareArrayOfOwner.length -= 1;

      // clear any previously approved ownership exchange
      if (IndexToApproved[_tokenId] != address(0)) {
        delete IndexToApproved[_tokenId];
      } 
    }
    //transfer ownership
    IndexToOwner[_tokenId] = _to;
    ownerToRareArray[_to].push(_tokenId);
    indexOfOwnedToken[_tokenId] = ownerToRareArray[_to].length - 1;
    // Emit the transfer event.
    Transfer(_from != address(0) ? _from : this, _to, _tokenId);
  }

  /// @notice Returns all the relevant information about a specific tokenId.
  /// @param _tokenId The tokenId of the rarecard.
  function getRareInfo(uint256 _tokenId) external view returns (
      uint256 sellingPrice,
      address owner,
      uint256 nextPrice,
      uint256 rareClass,
      uint256 cardId,
      uint256 rareValue
  ) {
    RareCard storage rarecard = rareArray[_tokenId];
    sellingPrice = IndexToPrice[_tokenId];
    owner = IndexToOwner[_tokenId];
    nextPrice = SafeMath.div(SafeMath.mul(sellingPrice,125),100);
    rareClass = rarecard.rareClass;
    cardId = rarecard.cardId;
    rareValue = rarecard.rareValue;
  }

  /// @notice Returns all the relevant information about a specific tokenId.
  /// @param _tokenId The tokenId of the rarecard.
  function getRarePLATInfo(uint256 _tokenId) external view returns (
    uint256 sellingPrice,
    address owner,
    uint256 nextPrice,
    uint256 rareClass,
    uint256 cardId,
    uint256 rareValue
  ) {
    RareCard storage rarecard = rareArray[_tokenId];
    sellingPrice = SafeMath.mul(IndexToPrice[_tokenId],PLATPrice);
    owner = IndexToOwner[_tokenId];
    nextPrice = SafeMath.mul(SafeMath.div(SafeMath.mul(sellingPrice,125),100),PLATPrice);
    rareClass = rarecard.rareClass;
    cardId = rarecard.cardId;
    rareValue = rarecard.rareValue;
  }


  function getRareItemsOwner(uint256 rareId) external view returns (address) {
    return IndexToOwner[rareId];
  }

  function getRareItemsPrice(uint256 rareId) external view returns (uint256) {
    return IndexToPrice[rareId];
  }

  function getRareItemsPLATPrice(uint256 rareId) external view returns (uint256) {
    return SafeMath.mul(IndexToPrice[rareId],PLATPrice);
  }

  function setRarePrice(uint256 _rareId, uint256 _price) external onlyAccess {
    IndexToPrice[_rareId] = _price;
  }

  function rareStartPrice() external pure returns (uint256) {
    return startPrice;
  }

  /// ERC721
  /// @notice Count all the rare items assigned to an owner
  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return ownerToRareArray[_owner].length;
  }

  /// @notice Find the owner of a rare item
  function ownerOf(uint256 _tokenId) external view returns (address _owner) {
    return IndexToOwner[_tokenId];
  }

  /// @notice Transfers the ownership of a rare item from one address to another address
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable {
    _safeTransferFrom(_from, _to, _tokenId, data);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /// @dev steps to implement the safeTransferFrom
  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
    internal
    isValidToken(_tokenId)
    onlyOwnerOf(_tokenId) 
  {
    address owner = IndexToOwner[_tokenId];
    require(owner != address(0) && owner == _from);
    require(_to != address(0));
            
    _transfer(_from, _to, _tokenId);

    // Do the callback after everything is done to avoid reentrancy attack
    /*uint256 codeSize;
    assembly { codeSize := extcodesize(_to) }
    if (codeSize == 0) {
        return;
    }*/
    bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);
    // bytes4(keccak256("onERC721Received(address,uint256,bytes)")) = 0xf0b9e5ba;
    require(retval == 0xf0b9e5ba);
  }

  // function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
  //   _transfer(msg.sender, _to, _tokenId);
  // }

  /// @notice Transfers the ownership of a rare item from one address to another address
  /// @dev Transfer ownership of a rare item, '_to' must be a vaild address, or the card will lost
  /// @param _from The current owner of rare item
  /// @param _to The new owner
  /// @param _tokenId The rare item to transfer
  function transferFrom(address _from, address _to, uint256 _tokenId) 
    external 
    isValidToken(_tokenId)
    onlyOwnerOf(_tokenId) 
    payable 
  {
    address owner = IndexToOwner[_tokenId];
    // require(_owns(_from, _tokenId));
    // require(_approved(_to, _tokenId));
    require(owner != address(0) && owner == _from);
    require(_to != address(0));
    _transfer(_from, _to, _tokenId);
  }

  //   /// For checking approval of transfer for address _to
  //   function _approved(address _to, uint256 _tokenId) private view returns (bool) {
  //     return IndexToApproved[_tokenId] == _to;
  //   }
  //  /// Check for token ownership
  //   function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
  //     return claimant == IndexToOwner[_tokenId];
  //   }

  /// @dev Set or reaffirm the approved address for a rare item
  /// @param _approved The new approved rare item controller
  /// @param _tokenId The rare item to approve
  function approve(address _approved, uint256 _tokenId) 
    external 
    isValidToken(_tokenId)
    onlyOwnerOf(_tokenId) 
    payable 
  {
    address owner = IndexToOwner[_tokenId];
    require(operatorToApprovals[owner][msg.sender]);
    IndexToApproved[_tokenId] = _approved;
    Approval(owner, _approved, _tokenId);
  }


  /// @dev Enable or disable approval for a third party ("operator") to manage all your asset.
  /// @param _operator Address to add to the set of authorized operators.
  /// @param _approved True if the operators is approved, false to revoke approval
  function setApprovalForAll(address _operator, bool _approved) 
    external 
  {
    operatorToApprovals[msg.sender][_operator] = _approved;
    ApprovalForAll(msg.sender, _operator, _approved);
  }

  /// @dev Get the approved address for a single rare item
  /// @param _tokenId The rare item to find the approved address for
  /// @return The approved address for this rare item, or the zero address if there is none
  function getApproved(uint256 _tokenId) external view isValidToken(_tokenId) returns (address) {
    return IndexToApproved[_tokenId];
  }

  /// @dev Query if an address is an authorized operator for another address
  /// @param _owner The address that owns the rare item
  /// @param _operator The address that acts on behalf of the owner
  /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    return operatorToApprovals[_owner][_operator];
  }

  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() public pure returns(string) {
    return "CryptoMagicAcademy";
  }

  /// @notice An abbreviated name for NFTs in this contract
  function symbol() public pure returns(string) {
    return "MAC";
  }

  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  // function tokenURI(uint256 _tokenId) external view returns (string);

  // function takeOwnership(uint256 _tokenId) public {
  //   require(IndexToApproved[_tokenId] == msg.sender);
  //   address owner = ownerOf(_tokenId);
  //   _transfer(owner, msg.sender, _tokenId);
  // }

  // function implementsERC721() public pure returns (bool) {
  //   return true;
  // }

  /// @notice Count rare items tracked by this contract
  /// @return A count of valid rare items tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() external view returns (uint256) {
    return rareArray.length -1;
  }

  /// @notice Enumerate valid rare items
  /// @dev Throws if `_index` >= `totalSupply()`.
  /// @param _index A counter less than `totalSupply()`
  /// @return The token identifier for the `_index`the rare item,
  ///  (sort order not specified)
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index <= (rareArray.length - 1));
    return _index;
  }

  /// @notice Enumerate rare items assigned to an owner
  /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
  ///  `_owner` is the zero address, representing invalid rare items.
  /// @param _owner An address where we are interested in rare items owned by them
  /// @param _index A counter less than `balanceOf(_owner)`
  /// @return The token identifier for the `_index`the rare item assigned to `_owner`,
  ///   (sort order not specified)
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    require(_index < ownerToRareArray[_owner].length);
    if (_owner != address(0)) {
      uint256 tokenId = ownerToRareArray[_owner][_index];
      return tokenId;
    }
  }

  /// @param _owner The owner whose celebrity tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
  ///  expensive (it walks the entire Persons array looking for persons belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) external view returns(uint256[]) {
    uint256 tokenCount = ownerToRareArray[_owner].length;
    if (tokenCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalRare = rareArray.length - 1;
      uint256 resultIndex = 0;

      uint256 tokenId;
      for (tokenId = 0; tokenId <= totalRare; tokenId++) {
        if (IndexToOwner[tokenId] == _owner) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  //transfer token 
  function transferToken(address _from, address _to, uint256 _tokenId) external onlyAccess {
    _transfer(_from,  _to, _tokenId);
  }

  // transfer token in contract-- for raffle
  function transferTokenByContract(uint256 _tokenId,address _to) external onlyAccess {
    _transfer(thisAddress,  _to, _tokenId);
  }

  // 拥有稀有卡牌的名单以及价格 
  function getRareItemInfo() external view returns (address[], uint256[], uint256[]) {
    address[] memory itemOwners = new address[](rareArray.length-1);
    uint256[] memory itemPrices = new uint256[](rareArray.length-1);
    uint256[] memory itemPlatPrices = new uint256[](rareArray.length-1);
        
    uint256 startId = 1;
    uint256 endId = rareArray.length-1;
        
    uint256 i;
    while (startId <= endId) {
      itemOwners[i] = IndexToOwner[startId];
      itemPrices[i] = IndexToPrice[startId];
      itemPlatPrices[i] = SafeMath.mul(IndexToPrice[startId],PLATPrice);
      i++;
      startId++;
    }   
    return (itemOwners, itemPrices, itemPlatPrices);
  }
}