
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Compile and deploy the contract
    const MasterNFTFactory = await ethers.getContractFactory("MintPadCollectionFactory");
    const masterNFTFactory = await MasterNFTFactory.deploy();

    console.log("MasterNFTFactory deployed to:", masterNFTFactory);
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
