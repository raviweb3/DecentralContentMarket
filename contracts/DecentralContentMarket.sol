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
        uint48   accuralPlayedCount;
        uint48   totalPlayedCount;
        bool     isListedAsContent;  
        bool     isOnSale;
        uint256  price ether;
    }

    event NftListed(uint256 indexed tokenId, CATEGORY indexed category, MEDIA indexed media, address owner);

    NFTItem[] private s_listing;
    mapping(uint256 => NFTItem) public s_idToListing;
    mapping(address => NFTItem[]) public s_ownerToListing;
   
    Counters.Counter private s_listedtokenIds;

    NFTCollection  private s_nft;
    DecentralToken private s_token;

    address payable private s_owner;

    // pay per play should be based on Media type
    // Based on director value, A DAO decided rate
    uint256 private constant c_payPerPlay = 10 ether;
    
    constructor(NFTCollection _nft, DecentralToken _token){
        s_nft = _nft;
        s_token = _token;
    }

    function createNft(string memory tokenURI, uint256 price, CATEGORY category, MEDIA media) public payable returns(uint256){
        require( price > 0," List with price greater than 0");
        uint256 tokenId = s_nft.mintToken(tokenURI);    
        NFTItem storage item = NFTItem(tokenId, block.timestamp, msg.sender,category,media,0,0,false,false,price);
        s_listing.push(item);
        s_idToListing[tokenId] = item;
        s_ownerToListing[msg.sender].push(item);
    }

    function listNftAsDecentralizedContent(uint256 tokenId) public payable{
        require(s_idToListing[tokenId].owner === msg.sender, "Only owner of the NFT can list as Decentralized Content.");       
  
        NFTItem storage item = s_idToListing[tokenId]

        item.isListedAsContent = true;
        item.accuralTimestamp = block.timestamp;

        // Transfer the ownership to smart contract and lock it.
        _transfer(msg.sender, address(this), tokenId);
        s_listedtokenIds.increment();
    }

    function DelistNftAsDecentralizedContent(uint256 tokenId) public payable{
        require(s_idToListing[tokenId].owner == msg.sender, "Only owner of the NFT can list as Decentralized Content.");       
        require(s_idToListing[tokenId].isListedAsContent == false, "Your NFT is not listed as Decentralized Content.");  

        NFTItem storage item = s_idToListing[tokenId]

        item.isListedAsContent = false;

        // Calculate Rewards if earned.

        // Transfer the ownership to smart contract and lock it.
        _transfer(address(this),msg.sender, tokenId);
    }

    function listNftForSale(uint256 tokenId) public payable{
        require(s_idToListing[tokenId].owner == msg.sender, "Only owner of the NFT can list for Sale.");    
        require(s_idToListing[tokenId].isListedAsContent == false, "Should not be lised as Decentralized Content.");    

        NFTItem storage item = s_idToListing[tokenId]

        item.isOnSale = true;
        item.accuralTimestamp = 0;
    }

    function executeBuy(uint256 tokenId) public payable{
        require(s_idToListing[tokenId].isOnSale == true,"NFT is not on sale");
        require(s_idToListing[tokenId].price ether == msg.value ether,"Insufficient funds"); 

        NFTItem storage item = s_idToListing[tokenId];

        token.transfer(item.owner, msg.value);       

        nft.transfer(item.owner, msg.sender, tokenId);

        item.owner = msg.sender;
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
        nftItem.accuralPlayedCount = nftItem.accuralPlayedCount + 1;
        nftItem.totalPlayedCount = nftItem.totalPlayedCount + 1;
    }
      
    function earnings() public view returns(uint256 earnings){ 
         uint256 earned = 0;
         NFTItem[] memory nftItems = s_ownerToListing[msg.sender];

         for(uint i =0; i< nftItems.length; i++){
          NFTItem nftItem = nftItems[i];
          earned += (c_payPerPlay * nftItem.accuralPlayedCount);
         }
         return earned;
    }

    function withdrawEarnings() public payable {
         uint256 earned = 0;
         NFTItem[] memory nftItems = s_ownerToListing[msg.sender];

         for(uint i =0; i< nftItems.length; i++){
          NFTItem nftItem = nftItems[i];
          earned += (c_payPerPlay * nftItem.accuralPlayedCount);
         }

         require(earned > 0,"No earns to withdraw");

         if(earned > 0){
           // transfer the funds to Owner 
           token.mint(msg.sender, earned);
         }
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