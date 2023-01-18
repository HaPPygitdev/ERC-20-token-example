const { expect } = require("chai")
const { ethers } = require("hardhat")
const tokenJSON =  require("../artifacts/contracts/token_erc20.sol/SoulToken.json")

describe("SoulShop", function() {
    let owner
    let buyer
    let router
    let erc20

    beforeEach(async function() {
        [owner, buyer] = await ethers.getSigners()

        const SoulShop = await ethers.getContractFactory("SoulShop", owner)
        router = await SoulShop.deploy()
        await router.deployed()

        erc20 = new ethers.Contract(await router.token(), tokenJSON.abi, owner) // подключение к существующему смарт-контракту
    })

    it("owner and token should exist", async function(){
        expect(await router.owner()).to.eq(owner.address)

        expect(await router.token()).to.be.properAddress
    })

    it("allows to buy", async function(){
        const tokenAmount = 3
        const txData = {
            value:tokenAmount,
            to: router.address
        }

        const tx = await buyer.sendTransaction(txData)
        await tx.wait()

        expect(await erc20.balanceOf(buyer.address)).to.eq(tokenAmount)

        await expect(() => tx).to.changeEtherBalance(router, tokenAmount)

        await expect(tx).to.emit(router, "Purchase").withArgs(tokenAmount, buyer.address)
    })

    it("allows to sell", async function(){
        const tx = await buyer.sendTransaction({
            value: 30,
            to: router.address
        })
        await tx.wait()

        const sellAmount = 20

        const approval = await erc20.connect(buyer).approve(router.address, sellAmount)
        await approval.wait()

        const sellTx = await router.connect(buyer).sell(sellAmount)

        expect(await erc20.balanceOf(buyer.address)).to.eq(10)

        await expect(() => sellTx).to.changeEtherBalance(router, -sellAmount)

        await expect(sellTx).to.emit(router, "Sale").withArgs(sellAmount, buyer.address)
    })
})