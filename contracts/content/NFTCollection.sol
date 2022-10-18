// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTCollection is ERC721URIStorage, ERC721Enumerable, Ownable    {
    using Counters for Counters.Counter; 
   
    Counters.Counter private s_tokenIds;

    address payable private s_owner;

    constructor() ERC721("NFTCollection","DCNFT"){
        s_owner = payable(msg.sender);
    }

    function mintToken(string memory tokenURI) public payable returns(uint256){
        s_tokenIds.increment();
        uint256 currentTokenId = s_tokenIds.current();
   
        _safeMint(msg.sender, currentTokenId);
        _setTokenURI(currentTokenId, tokenURI);

        return currentTokenId;
    }

    function mintedTokensCount() public view returns (uint256){
        return s_tokenIds.current();
    }
   

    function executeSale(uint256 tokenId) public payable {
         ListedToken storage currentItem = s_idToListedToken[tokenId];
         require(msg.value == currentItem.price,"Not Enough ether send to buy this NFT");   
         s_idToListedToken[tokenId].isOnSale = true;
         s_idToListedToken[tokenId].seller = payable(msg.sender);
         s_itemsSold.increment();

         // Tranfer from Smart contract to Sender   
         _transfer(address(this), msg.sender, tokenId);

         // Provision for the next sale   
         approve(address(this), tokenId);

         // Pay the platform
         payable(s_owner).transfer(s_listPrice);
         // Pay to the seller
         payable(currentItem.seller).transfer(msg.value);
    }

    function updateListPrice(uint256 _listPrice) public {
        require(msg.sender ==  s_owner,"You must be owner to call this");
        s_listPrice = _listPrice;
    }

    function getListPrice() public view returns(uint256){
        return s_listPrice;
    }

    function getLatestListedToken() public view returns(ListedToken memory){
        uint256 currentTokenId = s_tokenIds.current();
        return s_idToListedToken[currentTokenId];
    }

    function getListedForTokenId(uint256 tokenId) public view returns(ListedToken memory){
        return s_idToListedToken[tokenId];
    }

    function getCurrentTokenId() public view returns(uint256){
        return s_tokenIds.current();
    }
}