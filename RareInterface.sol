pragma solidity ^0.4.18;

interface RareInterface {
  function getRareItemsOwner(uint256 rareId) external view returns (address);
  function getRareItemsPrice(uint256 rareId) external view returns (uint256);
  function getRareItemsPLATPrice(uint256 rareId) external view returns (uint256);
  function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens);
  function getRareInfo(uint256 _tokenId) external view returns (
    uint256 sellingPrice,
    address owner,
    uint256 nextPrice,
    uint256 rareClass,
    uint256 cardId,
    uint256 rareValue
  ); 
   function getRarePLATInfo(uint256 _tokenId) external view returns (
    uint256 sellingPrice,
    address owner,
    uint256 nextPrice,
    uint256 rareClass,
    uint256 cardId,
    uint256 rareValue
  );
  function transferToken(address _from, address _to, uint256 _tokenId) external;
  function transferTokenByContract(uint256 _tokenId,address _to) external;
  function setRarePrice(uint256 _rareId, uint256 _price) external;
  function rareStartPrice() external view returns (uint256);
  function totalSupply() external view returns (uint256 total);
}
