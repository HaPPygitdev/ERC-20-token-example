const hre = require("hardhat")
const ethers = hre.ethers

async function main() {
    const [signer] = await ethers.getSigners()

    const Erc = await ethers.getContractFactory('SoulShop', signer)
    const erc = await Erc.deploy()
    await erc.deployed()
    console.log(erc.address)
    console.log(await erc.token())
}

main()
    .then(()=> process.exit(0))
    .catch((error) => {
        console.log(error);
        process.exit(1)
    });

// команда для запуска скрипта => деплоя контракта в локальную сеть
// npx hardhat run scripts\deploy_erc20.js --network localhost 