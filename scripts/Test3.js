// scripts/deployFactory.js

const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying MintpadCollectionFactory with the account:", deployer.address);

    // Get the contract factory for MintpadCollectionFactory
    const MintpadCollectionFactory = await ethers.getContractFactory("MintpadCollectionFactory");
    
    // Deploy the factory contract
    const mintpadCollectionFactory = await MintpadCollectionFactory.deploy();
    console.log("MintpadCollectionFactory deployed to:", mintpadCollectionFactory.address);

    // Initialize the factory with the ERC721 and ERC1155 addresses
    const erc721Implementation = "0xBA2C62F72bCBCE911E15477F43b7fA1D5B342898";
    const erc1155Implementation = "0x91955e6972f9f429cC76D4125f9dd79e342f2A91";

    const tx = await mintpadCollectionFactory.initialize(erc721Implementation, erc1155Implementation);
    await tx.wait();
    console.log("MintpadCollectionFactory initialized successfully with ERC721 and ERC1155 implementations.");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
