// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//Openzeppelin libraries
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Define the contract of NTU_TICKET token
contract NTU_TICKET is ERC721Enumerable, Ownable {
    using Strings for uint256;
 
    string public baseURI; //The IPFS pointer(hash) of metadata files
    string public baseExtension = ".json";//The metadata should be in the format of .json
    uint256 public cost = 0.0001 ether;  //The price of each NFT (0.0001 ether)
    uint256 public maxSupply = 20;    //Maximum supply (20)
    uint256 public maxMintAmount = 3;  //Maximum mint limitation per transaction (3)
    uint256 public presalePeriod = 200; //Duration of presale (200s)

    mapping(address => bool) public whitelisted;

    uint256 public deploymentTimestamp;


    constructor(string memory _initBaseURI) ERC721("NTU_TICKET", "NTU") Ownable(msg.sender) {
	//Deployment and initialization of the token
        deploymentTimestamp = block.timestamp; //The current block.timestamp is used as the start point of pre-sale
        setBaseURI(_initBaseURI);//Set the initial IPFS address of metadata
        mint(msg.sender, 1);// Mint 1 genesis token to creator's wallet
    }

    // Call the IPFS pointer(hash) of metadata files
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // The following functions can called by the public wallets

    //mint fucntion(pre-sale and public-sale)
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        bool Presale = check_presale();

        require(_mintAmount > 0);//mintAmount is greater than zero
        require(_mintAmount <= maxMintAmount); //The mintAmount does not exceed the limitation per transaction
        require(supply + _mintAmount <= maxSupply);//Current total supply does not exceed the maximum supply after purchasing



        if (msg.sender != owner()) {
            if(whitelisted[msg.sender] != true) { 
                require(!Presale, "Please wait for public sale!");
                require(msg.value >= cost * _mintAmount);
            }
        } //If the user is non-whitelisted, he can only purchase the tokens during public-sale

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_to, supply + i);
        } //If the user is whitelisted, he can mint the tokens at anytime for free
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory){
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    } //Get the IDs of all NTU-TOKENs held by the current wallet

    function verifyAsset(address _owner) public view returns (bool){
        bool isOwner = true;
        if(balanceOf(_owner)>0){
            return isOwner;
        }
        return !isOwner;
    } //Verify if the current wallet is the holder of the NTU-TOKEN

    function check_presale() public view returns (bool){
        bool _Presale = true;
        uint256 currentTimestamp = block.timestamp;
        if(currentTimestamp >= deploymentTimestamp + presalePeriod){
            _Presale = false;
        }
        return _Presale;
    } //Check if current state is pre-sale

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_ownerOf(tokenId) != address(0),"ERC721Metadata: URI query for nonexistent token");


        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    } //assemble the IPFS pointer(hash) of each token's metadata

    //The following functions can only called by the owner
    //set new price of each token
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    //set new presale duration
    function setpresalePeriod(uint256 _newpresalePeriod) public onlyOwner {
        presalePeriod = _newpresalePeriod;
    }
    //start a new presale at current block.timestamp
    function setnewpresale() public onlyOwner {
        deploymentTimestamp = block.timestamp;
    }

    //set a new maximum mint limitation per transaction
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    //set a new maximum supply
    function setmaxSupply(uint256 _newmaxSupply) public onlyOwner {
        maxSupply = _newmaxSupply;
    }
    //set a new IPFS pointer(hash)of metadata files
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    //Add a new wallet address to the whitelist
    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }
    //Remove the wallet address from the whitelist
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }
    //Withdraw the balance from the contract to the creator's wallet
    function withdraw() public payable onlyOwner {

        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);

    }
    }