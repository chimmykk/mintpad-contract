
const { ethers } = require("hardhat")

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);


    const MasterNFTFactory = await ethers.getContractFactory("MintpadERC1155Factory");
    const masterNFTFactory = await MasterNFTFactory.deploy();

    console.log("MasterNFTFactory deployed to:", masterNFTFactory);
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
