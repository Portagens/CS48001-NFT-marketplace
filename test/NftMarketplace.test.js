const NftMarketplace = artifacts.require("TurkishFootballCards");

require("chai")
    .use(require('chai-as-promised'))
    .should()



contract('TurkishFootballCards', (accounts) => {
        let nftCount;

        before(async() => {

            marketplaceInstance = await NftMarketplace.deployed();
            nftCount = await NftMarketplace.nftCount;
        })
        
        it("should be deployed", async() => {
            
             const address = await marketplaceInstance.address;
             assert.notEqual(address, 0x0);
             assert.notEqual(address, '');
             assert.notEqual(address, null);
             assert.notEqual(address, undefined); 
            
        }) 
        it("Has the right name", async() =>{
            const name = await marketplaceInstance.name;
            assert.notEqual(name, "");
            assert.notEqual(name, "hello");
            assert.notEqual(name, null);
        })


        it("Should mint an nft", async() => {
    

            const mint_result = await marketplaceInstance.mint(web3.utils.toWei('10','Ether'), "https://www.thisIsTheURIofThisNFT.com/215",{from:accounts[0], value:web3.utils.toWei('0.002', 'Ether')});

            const count = await marketplaceInstance.nftCount();
            const creation_event = mint_result.logs[0].args;
            const nft_event = mint_result.logs[1].args;

            //make sure counter incremented
            assert.equal(toString(count),toString(nftCount + 1), 'Nft not created');
            //test the sold state of the nft
            assert.equal(false, creation_event.soldBefore);
            //check the price of the new nft
            assert.equal(web3.utils.toWei('10','Ether'), creation_event.price);
            //check the owner of the new nft
            assert.equal(creation_event.owner, nft_event.to, accounts[0]);
            //check the TokenID
            assert.equal(toString(creation_event.id), toString(nft_event.TokenId), toString(nftCount));



            //failures

            //try to mint with the wrong account
            await marketplaceInstance.mint(web3.utils.toWei('10','Ether'), "https://www.thisIsTheURIofThisNFT.com/215", {from:null, value:web3.utils.toWei('0.002', 'Ether')}).should.be.rejected;
            await marketplaceInstance.mint(web3.utils.toWei('10','Ether'), "https://www.thisIsTheURIofThisNFT.com/215", {from:'', value:web3.utils.toWei('0.002', 'Ether')}).should.be.rejected;
            await marketplaceInstance.mint(web3.utils.toWei('10','Ether'), "https://www.thisIsTheURIofThisNFT.com/215", {from:0, value:web3.utils.toWei('0.002', 'Ether')}).should.be.rejected;
            await marketplaceInstance.mint(web3.utils.toWei('10','Ether'), "https://www.thisIsTheURIofThisNFT.com/215", {from:accounts[1], value:web3.utils.toWei('0.002', 'Ether')}).should.be.rejected;

            //try to mint with wrong value on the message
            await marketplaceInstance.mint(web3.utils.toWei('10','Ether'), "https://www.thisIsTheURIofThisNFT.com/215", {from:accounts[0]}).should.be.rejected;
            await marketplaceInstance.mint(web3.utils.toWei('10','Ether'), "https://www.thisIsTheURIofThisNFT.com/215", {from:accounts[0], value:web3.utils.toWei('0.001', 'Ether')}).should.be.rejected;






        })


        it("Should buy an nft", async() => {

            const previous_balance = await web3.eth.getBalance(accounts[0]);
            const buy = await marketplaceInstance.purchaseCard(0, {from: accounts[1], value: web3.utils.toWei('10','Ether')});
            const new_balance = await web3.eth.getBalance(accounts[0]);
            const nft_info = await marketplaceInstance.nfts(0);

            const purchase_event = await buy.logs[0].args;
            const transfer_event = await buy.logs[1].args;
            

            
            //see ownership transfer
            assert.equal(transfer_event.to, accounts[1], purchase_event.owner, 'Ownership change is not correct');
            //check if the ballance changed 
            assert.notEqual(previous_balance, new_balance, 'Money wasnt transfered');
            //check if the soldBefore changed
            assert.ok(nft_info.soldBefore, 'The nft state was not changed');


            //failures
            
            //not enough value in the message
            await marketplaceInstance.purchaseCard(0, {from: accounts[1], value: '10'}).should.be.rejected;
            //use owners account (Turkish Football federation)
            await marketplaceInstance.purchaseCard(0, {from: accounts[0], value: web3.utils.toWei('10','Ether')}).should.be.rejected;
            //insert invalid nftID
            await marketplaceInstance.purchaseCard(2, {from: accounts[1], value: web3.utils.toWei('10','Ether')}).should.be.rejected;            
        })

    
    })