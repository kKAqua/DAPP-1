// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract NTU_Transaction is IERC721Receiver {
    event List(address indexed seller, address indexed nft_add, uint256 indexed token_id, uint256 price);
    event Remove(address indexed seller, address indexed nft_add, uint256 indexed token_id);
    event Change(address indexed seller, address indexed nft_add, uint256 indexed token_id, uint256 new_price);
    event Purchase(address indexed buyer, address indexed nft_add, uint256 indexed token_id, uint256 price);

    //define the order properties of each NFT
    struct Order {
        address owner;
        uint256 price;
    }

    //
    struct NFT_listed {
        uint256 token_id;
        uint256 price;
    }
   
    mapping(address => mapping(uint256 => Order)) public nft_order;
    mapping(address => mapping(uint256 => NFT_listed)) public nft_listed;

    //called when the contract receives ether
    receive() external payable {}

    //called when the calling data is empty or the called function does not exist
    fallback() external payable {}

    
    //list NFT, the price is Ethereum (unit is wei)
    function list(address nft_add, uint256 token_id, uint256 price) public {
        //declare IERC721 interface contract variables
        IERC721 nft = IERC721(nft_add); 
        //confirm that the contract is authorized
        require(nft.getApproved(token_id) == address(this), "No NFT contract authorization"); 
        require(price >= 0, "The price must be greater than or equal to 0"); 
        //set NFT holders and prices
        Order storage order = nft_order[nft_add][token_id]; 
        order.owner = msg.sender;
        order.price = price;
        //transfer NFT to the contract
        nft.safeTransferFrom(msg.sender, address(this), token_id);

        emit List(msg.sender, nft_add, token_id, price);
    }

    //To list NFT in batches, input: the contract address of the generated NTF, the token_id array of NFT ([1, 3, 4]), and the unified pricing. (The contract addresses of these NFTs must be the same)
    function batch_list(address nft_add, uint256[] memory token_ids, uint256 price) public {
        require(price >= 0, "The price must be greater than or equal to 0");
        for (uint i = 0; i < token_ids.length; i++) {
            list(nft_add, token_ids[i], price);
        }
    }

    //search: input the nft address to return the id and price of all nfts listed on this contract (get the corresponding price for purchase)
    function search_NFTs(address nft_add) public view returns (NFT_listed[] memory) {
        IERC721Enumerable nft = IERC721Enumerable(nft_add);
        uint256 totalSupply = nft.totalSupply();
        NFT_listed[] memory listed_nft = new NFT_listed[](totalSupply);
        uint256 counter = 0;
        
        for (uint256 i = 0; i < totalSupply; i++) {
            uint256 token_id = nft.tokenByIndex(i);
            if (nft_order[nft_add][token_id].owner != address(0)) {  
                listed_nft[counter] = NFT_listed(token_id, nft_order[nft_add][token_id].price);
                counter++;
            }
        }
        
        // Adjust the size of the array before returning if necessary
        if (counter != totalSupply) {
            NFT_listed[] memory new_listedNFTs = new NFT_listed[](counter);
            for (uint256 j = 0; j < counter; j++) {
                new_listedNFTs[j] = listed_nft[j];
            }
            return new_listedNFTs;
        }
        return listed_nft;
    }    

    //remove ntf
    function remove(address nft_add, uint256 token_id) public {
        Order storage order = nft_order[nft_add][token_id]; 
        require(order.owner == msg.sender, "Not owner of this nft"); 

        IERC721 nft = IERC721(nft_add);
        require(nft.ownerOf(token_id) == address(this), "Invalid order"); 

        //transfer the NFT to the seller
        nft.safeTransferFrom(address(this), msg.sender, token_id);
        delete nft_order[nft_add][token_id]; 

        emit Remove(msg.sender, nft_add, token_id);
    }

    //To remove NFT in batches
    function batch_remove(address nft_add, uint256[] memory token_ids) public {
        for (uint i = 0; i < token_ids.length; i++) {
            remove(nft_add, token_ids[i]);
        }
    }

    //change nft price
    function change_price(
        address nft_add,
        uint256 token_id,
        uint256 new_price
    ) public {
        require(new_price >= 0, "The price must be greater than or equal to 0"); 
        Order storage order = nft_order[nft_add][token_id]; 
        require(order.owner == msg.sender, "Not owner of this nft"); 

        IERC721 nft = IERC721(nft_add);
        require(nft.ownerOf(token_id) == address(this), "Invalid order"); 
        //change nft price
        order.price = new_price;

        emit Change(msg.sender, nft_add, token_id, new_price);
    }

    //Buyer buys NFT, the contract is nft_add, token_id is token_id, ETH is required when calling the function
    function purchase(address nft_add, uint256 token_id) public payable {
        Order storage order = nft_order[nft_add][token_id]; 
        require(order.price >= 0, "The price must be greater than or equal to 0"); 
        require(msg.value >= order.price, "Need more ether"); 

        IERC721 nft = IERC721(nft_add);
        require(nft.ownerOf(token_id) == address(this), "Invalid order"); 

        //transfer the NFT to the buyer
        nft.safeTransferFrom(address(this), msg.sender, token_id);
        //transfer ETH to the seller and refund the excess ETH to the buyer
        payable(order.owner).transfer(order.price);
        payable(msg.sender).transfer(msg.value - order.price);

        delete nft_order[nft_add][token_id]; 

        emit Purchase(msg.sender, nft_add, token_id, order.price);
    }

    //Implement onERC721Received of {IERC721Receiver} to receive ERC721 tokens
    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* token_id */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}



