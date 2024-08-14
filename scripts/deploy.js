// scripts/deploy_factory.js
const { ethers } = require("hardhat");

async function main() {
    // Get the ContractFactory and signers
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Compile and deploy the contract
    const MasterNFTFactory = await ethers.getContractFactory("MintPadERC721Factory");
    const masterNFTFactory = await MasterNFTFactory.deploy();

    console.log("MasterNFTFactory deployed to:", masterNFTFactory);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
