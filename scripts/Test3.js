// scripts/deployFactory.js

const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying MintpadCollectionFactory with the account:", deployer.address);

    // Get the contract factory for MintpadCollectionFactory
    const MintpadCollectionFactory = await ethers.getContractFactory("MintpadCollectionFactory");
    
    // Deployment platform addresses (must be non-empty)
    const platformAddresses = [deployer.address]; // Example platform address
    const platformFee = ethers.utils.parseEther("0.01"); // Set platform fee (for example, 0.01 Ether)

    // Deploy the factory contract
    const mintpadCollectionFactory = await MintpadCollectionFactory.deploy();
    await mintpadCollectionFactory.deployed();
    console.log("MintpadCollectionFactory deployed to:", mintpadCollectionFactory.address);

    // Initialize the factory with the ERC721 and ERC1155 addresses
    const erc721Implementation = "0xD7196365cb9528DE0f06c43F4B02AF93D6B65877"; // Update to your ERC721 implementation address
    const erc1155Implementation = "0x407E678F66Dd4F481F0655DAD1125d54fa735F79"; // Update to your ERC1155 implementation address

    const tx = await mintpadCollectionFactory.initialize(
        erc721Implementation,
        erc1155Implementation,
        platformAddresses,
        platformFee
    );
    await tx.wait();
    console.log("MintpadCollectionFactory initialized successfully with ERC721 and ERC1155 implementations.");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
