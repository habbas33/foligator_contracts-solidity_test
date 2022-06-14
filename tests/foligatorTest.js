const { expect, assert } = require("chai");

describe("FgtToken", async function () {
    ////////////////////////////////
    /////CONTRACT DEPLOYMENT////////
    ////////////////////////////////

    // *** deploy FGT token and get contract address
    const metadata = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/FgtToken.json'))
    const accounts = await web3.eth.getAccounts()
    let fgtToken = new web3.eth.Contract(metadata.abi)
    fgtToken = fgtToken.deploy({data: metadata.data.bytecode.object})
    
    const tokenContractInstance = await fgtToken.send({
        from: accounts[0],
        gas: 3000000
    })
    fgtTokenContractAddress = tokenContractInstance.options.address;
    // await new Promise(r => setTimeout(r, 2000));
    fgtToken = new web3.eth.Contract(metadata.abi,fgtTokenContractAddress)
    console.log('fgtToken contract Address: ' + fgtTokenContractAddress);

    // *** deploy FgtTokenSale and get contract address
    const metadata_tokenSale = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/FgtTokenSale.json'))
    let fgtTokenSale = new web3.eth.Contract(metadata_tokenSale.abi)
    fgtTokenSale = fgtTokenSale.deploy({data: metadata_tokenSale.data.bytecode.object, arguments: [fgtTokenContractAddress]})
    
    const tokenSaleContractInstance = await fgtTokenSale.send({
        from: accounts[0],
        gas: 3000000
    })
    fgtTokenSaleContractAddress = tokenSaleContractInstance.options.address;
    fgtTokenSale = new web3.eth.Contract(metadata_tokenSale.abi,fgtTokenSaleContractAddress)
    console.log('fgtTokenSale contract Address: ' + fgtTokenSaleContractAddress);

   // *** deploy Controller and get contract address
    const metadata_controller = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/Controller.json'))
    let controller = new web3.eth.Contract(metadata_controller.abi)
    controller = controller.deploy({data: metadata_controller.data.bytecode.object, arguments: [fgtTokenContractAddress, fgtTokenSaleContractAddress]})
    
    const controllerContractInstance = await controller.send({
        from: accounts[0],
        gas: 3000000
    })
    controllerContractAddress = controllerContractInstance.options.address;
    controller = new web3.eth.Contract(metadata_controller.abi,controllerContractAddress)
    console.log('controller contract Address: ' + controllerContractAddress);

    /////////////////////////////////
    /////////// TEST ////////////////
    /////////////////////////////////

    it("FGT Contract initial value", async function () {
        // Check initial values
        expect((await fgtToken.methods.name().call())).to.equal("Foligator Token");
        console.log('fgtToken name: ' + (await fgtToken.methods.name().call()));
        expect((await fgtToken.methods.symbol().call())).to.equal("FGT");
        console.log('fgtToken symbol: ' + (await fgtToken.methods.symbol().call()));
        expect((await fgtToken.methods.totalSupply().call())).to.equal("0");
        console.log('fgtToken totalSupply: ' + (await fgtToken.methods.totalSupply().call()));
        expect((await fgtToken.methods._owner().call())).to.equal(accounts[0]);
        console.log('fgtToken _owner: ' + (await fgtToken.methods._owner().call()));
    });

    it('changed owner successfully', async () => {
        await fgtToken.methods.setOwner(controllerContractAddress.toString()).send({from : accounts[0]});
        expect((await fgtToken.methods._owner().call())).to.equal(controllerContractAddress);
        console.log('fgtToken _owner: ' + (await fgtToken.methods._owner().call()));
    })

    it("Controller initial mint", async function () {
        //call initial mint 
        console.log("**** initial minting **** ")
        await controller.methods.initialMint().send({from : accounts[0]});
        // Make sure all accounts have correct fgt holdings
        console.log("**** fgt holdings check **** ")
        
        expect((await controller.methods.getFgtHoldingOf(accounts[11]).call())).to.equal('2000000');
        console.log('fgt_holdings[_reserveAddress]: ' + await controller.methods.getFgtHoldingOf(accounts[11]).call())
        
        expect((await controller.methods.getFgtHoldingOf(accounts[12]).call())).to.equal('20000000');
        console.log('fgt_holdings[_liquidityAddress]: ' + await controller.methods.getFgtHoldingOf(accounts[12]).call())
        
        expect((await controller.methods.getFgtHoldingOf(accounts[13]).call())).to.equal('2000000');
        console.log('fgt_holdings[_marketingAddress] ' + await controller.methods.getFgtHoldingOf(accounts[13]).call())
        
        expect((await controller.methods.getFgtHoldingOf(accounts[14]).call())).to.equal('0');
        console.log('fgt_holdings[_teamAddress]: ' + await controller.methods.getFgtHoldingOf(accounts[14]).call())
        
        expect((await controller.methods.getFgtHoldingOf(fgtTokenSaleContractAddress.toString()).call())).to.equal('50000000');
        console.log('fgt_holdings[_tokenSaleContract]: '+ await controller.methods.getFgtHoldingOf(fgtTokenSaleContractAddress.toString()).call())
        
        expect((await fgtToken.methods.totalSupply().call())).to.equal('74000000');
        console.log('fgtToken totalSupply: ' + (await fgtToken.methods.totalSupply().call()));
    });

    it("Controller initial claim", async function () {
        // Make sure all accounts have correct fgt balance
        console.log("**** fgt balance check **** ")
        await controller.methods.claim().send({from : accounts[11]})
        expect((await fgtToken.methods.balanceOf(accounts[11]).call())).to.equal('2000000');
        console.log('fgt_balance[_reserveAddress]: ' + await fgtToken.methods.balanceOf(accounts[11]).call())

        await controller.methods.claim().send({from : accounts[12]})
        expect((await fgtToken.methods.balanceOf(accounts[12]).call())).to.equal('20000000');
        console.log('fgt_balance[_liquidityAddress]: ' + await fgtToken.methods.balanceOf(accounts[12]).call())

        await controller.methods.claim().send({from : accounts[13]})
        expect((await fgtToken.methods.balanceOf(accounts[13]).call())).to.equal('2000000');
        console.log('fgt_balance[_marketingAddress]: ' + await fgtToken.methods.balanceOf(accounts[13]).call())

        // await controller.methods.claim().send({from : accounts[14]}) //revert no tokens to claim
        // expect((await fgtToken.methods.balanceOf(accounts[14]).call())).to.equal('0');
        // console.log('fgt_balance[_teamAddress]: ' + await fgtToken.methods.balanceOf(accounts[14]).call())

        await controller.methods.tokenSaleClaim().send({from : accounts[0]})
        expect((await fgtToken.methods.balanceOf(fgtTokenSaleContractAddress).call())).to.equal('50000000');
        console.log('fgt_balance[_tokenSaleContract]: '+ await fgtToken.methods.balanceOf(fgtTokenSaleContractAddress).call())

         // Make sure all accounts have correct fgt holdings
        console.log("**** fgt holdings check **** ")
        
        expect((await controller.methods.getFgtHoldingOf(accounts[11]).call())).to.equal('0');
        console.log('fgt_holdings[_reserveAddress]: ' + await controller.methods.getFgtHoldingOf(accounts[11]).call())
        
        expect((await controller.methods.getFgtHoldingOf(accounts[12]).call())).to.equal('0');
        console.log('fgt_holdings[_liquidityAddress]: ' + await controller.methods.getFgtHoldingOf(accounts[12]).call())
        
        expect((await controller.methods.getFgtHoldingOf(accounts[13]).call())).to.equal('0');
        console.log('fgt_holdings[_marketingAddress] ' + await controller.methods.getFgtHoldingOf(accounts[13]).call())
        
        expect((await controller.methods.getFgtHoldingOf(accounts[14]).call())).to.equal('0');
        console.log('fgt_holdings[_teamAddress]: ' + await controller.methods.getFgtHoldingOf(accounts[14]).call())
        
        expect((await controller.methods.getFgtHoldingOf(fgtTokenSaleContractAddress.toString()).call())).to.equal('0');
        console.log('fgt_holdings[_tokenSaleContract]: '+ await controller.methods.getFgtHoldingOf(fgtTokenSaleContractAddress.toString()).call())
        
        expect((await fgtToken.methods.totalSupply().call())).to.equal('74000000');
        console.log('fgtToken totalSupply: ' + (await fgtToken.methods.totalSupply().call()));
    });

    // async function getRevertReason(txHash){
    //     console.log(`getTransaction`);
    //     const tx = await web3.eth.getTransaction(txHash).then(console.log);
    //     var result = await web3.eth.call(tx, tx.blockNumber)
    //     result = result.startsWith('0x') ? result : `0x${result}`
    //     if (result && result.substr(138)) {
    //         const reason = web3.utils.toAscii(result.substr(138))
    //         console.log('Revert reason:', reason)
    //         return reason
    //     } else {
    //         console.log('Cannot get reason - No return value')
    //     }
    // }
});
