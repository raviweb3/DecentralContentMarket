// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Imports
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./content/Catalogue.sol";
import "./DecentralToken.sol";
// NFTS
// ERC20 for reward
// DAO

contract DecentralContentMarket is Ownable, IERC721Receiver {
    using Counters for Counters.Counter;

    enum MEDIA{
        VIDEO,
        AUDIO,
        IMG
    }

    enum CATEGORY {
        MUSIC,
        COMEDY,
        EDUCATION,
        TECHNOLOGY
    }

    struct NFTItem {
        uint24   tokenId;
        uint48   listedTimestamp;
        address  owner;
        CATEGORY category;
        MEDIA    media;
        uint48   accuralTimestamp;
        uint48   playedCount;
        bool     isListed;  
    }

    event NftListed(uint256 indexed tokenId, CATEGORY indexed category, MEDIA indexed media, address owner);

    NFTItem[] private s_listing;
    mapping(uint256 => NFTItem) public s_idToListing;
    mapping(address => NFTItem[]) public s_ownerToListing;
   
    Counters.Counter private s_listedtokenIds;

    NFTCollection  private s_nft;
    DecentralToken private s_token;

    address payable private s_owner;
    
    constructor(NFTCollection _nft, DecentralToken _token){
        s_nft = _nft;
        s_token = _token;
    }

    function createNft(string memory tokenURI, uint256 price, CATEGORY category, MEDIA media) public payable returns(uint256){
        require( price > 0," List with price greater than 0");
        uint256 tokenId = s_nft.mintToken(tokenURI);    
        NFTItem storage item = NFTItem(tokenId, block.timestamp, msg.sender,category,media,0,0,false);
        s_listing.push(item);
        s_idToListing[tokenId] = item;
        s_ownerToListing[msg.sender][tokenId] = item;
    }

    function listNft(uint256 tokenId) public payable{
        require(s_idToListing[tokenId].owner === msg.sender, "Only owner of the NFT can list.");       
  
        NFTItem storage item = s_idToListing[tokenId]

        item.isListed = true;
        item.accuralTimestamp = block.timestamp;

        // Transfer the ownership to smart contract and lock it.
        _transfer(msg.sender, address(this), tokenId);
        s_listedtokenIds.increment();
    }

     function getListedNFTs() public view returns(NFTItem[] memory){
        // Number of items that are listed
        uint listedNftCount = s_listedtokenIds.current();
        NFTItem[] memory tokens = new NFTItem[](listedNftCount);
        
        // All the NFTS that are minted
        uint256 mintedNftCount = s_nft.mintedTokensCount();

        uint currentIndex = 0;
        for(uint i=0; i < mintedNftCount; i++){
            uint currentId = i + 1;
            NFTItem storage currentItem = s_idToListedToken[currentId];
            if(currentItem.isListed){
                // Only Listed items
                tokens[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }   
        return tokens;
    }

    // See if this logic works
    function getMyNFTs() public view returns (ListedToken[] memory){
        uint listedNftCount = s_listedtokenIds.current();
        NFTItem [] memory tokens = new NFTItem[];
      
        for(uint i=0; i < listedNftCount; i++){
            NFTItem storage currentItem = s_idToListedToken[i];
            if(currentItem.owner == msg.sender){
               tokens.push(currentItem);
            }
        }   
        // Return token information
        return tokens;
    }

    function playOnPlatform(uint256 tokenId) public payable{
        require(s_idToListing[tokenId].isListed == true,"Can play listed token only")

        NFTItem storage nftItem = s_idToListing[tokenId];
        // Record play
        nftItem.playedCount = nftItem.playedCount + 1;
    }
      
    function earningInfo() external view returns(uint256 earnings){ 
         uint256 tokenId;
         uint256 earned = 0;

         for(uint i =0; i< tokenIds.length; i++){
          tokenId = tokenIds[i];
          Stake memory staked = vault[tokenId];
          require(staked.owner == account, "not an owner");
          uint256 stakedAt = staked.timestamp;
          earned += c_dailyRewards * (block.timestamp - stakedAt)/ 1 days;
          vault[tokenId] = Stake({
            owner: account,
            tokenId: uint24(tokenId),
            timestamp:uint48(block.timestamp)
          });
         }

         if(earned > 0){
          earned = earned / c_dailyRewards;
          token.mint(account, earned);
         }

         if(_unstake){
           unstakeMany(account, tokenIds);
         }
         emit Claimed(account, earned);
    }

    function withdrawEarnings(){

    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns(bytes4)  {
      require(from==address(0x0), "Cannot send NFTs to vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }

}