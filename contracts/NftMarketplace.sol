// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts//security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @notice Smart Contract for the nft marketplace of the turkish football assocition
/// @dev Must receive payments for nft's (sell nfts), verify their creators id, create nfts

contract TurkishFootballCards is ERC721, ReentrancyGuard, Ownable
{
    address payable public TF_owner;
    uint256 public mintPrice = 0.002 ether;
    uint256 public nftCount = 0;
    mapping(uint256 => card) public nfts;

    
    struct card
    {
        uint256 id;
        address owner;
        bool soldBefore; 
        uint256 price;
    }

    event nft_sold
    (
        uint256 id,
        address owner,
        bool soldBefore,
        uint256 price
    );

    event nft_created(
        uint256 id,
        address owner,
        bool soldBefore,
        uint256 price
    );


    constructor() ERC721('TurkishFootball','SimpleMint')
    {
        TF_owner = payable(0x61cf35200B6998660f4b442Ecb85151F9CA98492); //address of the nft_minter/aka TFF
       
        setApprovalForAll(address(this),true); // aproove the contract to be able to admin the minted nfts
        //SetbaseURI("https://www.mynftforblockchainproject.com/safedeposit/"); //replace this with the actual address
        //nftMinter = 'address of the turkish football federation';     
        //call the constructor of the ERC721
    }

    
    function mint(uint256 _nft_price) external onlyOwner payable
    {
        address contractsAddress = address(this);
        
        //this funtion is responsible for the minting of new coins
        //only the Turkish Football federation is supposed to be able to mint
        require(msg.sender == TF_owner);
        //the message value should be equal to the minting cost
        require(msg.value >= mintPrice);
        //creating the new nft in the marketplace
        
        nfts[nftCount] = card({id: nftCount, owner: TF_owner, soldBefore: false, price: _nft_price});
        emit nft_created(nftCount, TF_owner, false, _nft_price); //event of the creation on the marketplace
        //actually creating the nft in the
        uint256 TokenID = nftCount;
        nftCount++;
        //mint(TF_owner);
        _safeMint(TF_owner, TokenID); //emits a {Transfer} event

    }

    function purchaseCard(uint256 _tokenID) external payable
    {
        //check correct id
        require(_tokenID >= 0 && _tokenID <= nftCount);
        address contractsAddress = address(this);
        

        //load nft information
        address owner = ownerOf(_tokenID);
        card memory _cardToSell = nfts[_tokenID];
        require(owner == TF_owner, "Invalid owner, nft does not belong to the Turkish football association");
        
        //check for funds 
        require(msg.value >= _cardToSell.price, "Unsufficient funds");
        
        //tranfer the funds (fund value can change after calling external functions, aka the safeTransferFrom)
        TF_owner.transfer(msg.value); // maybe not use this because of the Istambull fork and change in gas prices (not safe anymore)
    
        //transfer the nft
        ERC721(contractsAddress).safeTransferFrom(owner, msg.sender, _tokenID); //calls the transfer function with the contracts address(it's an authorized operator)
        //update the cards info
        _cardToSell.owner = msg.sender;
        _cardToSell.soldBefore = true;
        nfts[_tokenID] = _cardToSell;
        //event to log this, maybe not do it, cause the safeTransferFrom function already emits a {Transfer} event
        emit nft_sold(_tokenID, _cardToSell.owner, true, _cardToSell.price);

    }

    
}
