// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts//security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @notice Smart Contract for the nft marketplace of the turkish football assocition
/// @dev Must receive payments for nft's (sell nfts), verify their creators id, create nfts

contract TurkishFootballCards is ERC721URIStorage, ReentrancyGuard, Ownable
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


    constructor() ERC721('TurkishFootballFederation','Card Colection')
    {
        TF_owner = payable(0x61cf35200B6998660f4b442Ecb85151F9CA98492); //address of the nft_minter/aka TFF
       
        setApprovalForAll(address(this),true); // aproove the contract to be able to admin the minted nfts
        //nftMinter = 'address of the turkish football federation';     
        //call the constructor of the ERC721
    }

    
    function mint(uint256 _nft_price, string memory _tokenURI) external onlyOwner nonReentrant payable
    {
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
        _setTokenURI(TokenID, _tokenURI);

    }

    function purchaseCard(uint256 _tokenID) external nonReentrant payable
    {
        //check correct id
        require(_tokenID >= 0 && _tokenID <= nftCount, 'Invalid Token ID' );
        require(_exists(_tokenID),'Invalid Token ID' );
        address contractsAddress = address(this);
        

        //load nft information
        address owner = ownerOf(_tokenID);
        card memory _cardToSell = nfts[_tokenID];
        require(owner == TF_owner, "Invalid owner, nft does not belong to the Turkish football association");
        
        //check if owner is the seller
        require(msg.sender != owner, 'Seller cannout purchase an NFT');
        //check for funds 
        require(msg.value >= _cardToSell.price, "Unsufficient funds");
        
        //tranfer the funds (fund value can change after calling external functions, aka the safeTransferFrom)
        (bool transfer, bytes memory data) = TF_owner.call{value: msg.value}("");
        require(transfer, 'Failed to send Ether');
        //transfer the nft
                //update the cards info
        _cardToSell.owner = msg.sender;
        _cardToSell.soldBefore = true;
        nfts[_tokenID] = _cardToSell;
        //event to log this, maybe not do it, cause the safeTransferFrom function already emits a {Transfer} event
        emit nft_sold(_tokenID, _cardToSell.owner, true, _cardToSell.price);

        ERC721(contractsAddress).safeTransferFrom(owner, msg.sender, _tokenID); //calls the transfer function with the contracts address(it's an authorized operator)
        
        

    }

    fallback() external payable
    {
        require(msg.value == 0 && msg.sender == TF_owner); //revert anything not sent by the TFF
    }

    
}
