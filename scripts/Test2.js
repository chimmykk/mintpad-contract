// scripts/deployERC1155.js

const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying MintpadERC1155Collection with the account:", deployer.address);

    // Get the contract factory for MintpadERC1155Collection
    const MintpadERC1155Collection = await ethers.getContractFactory("MintpadERC1155Collection");
    
    // Deploy the contract (initial deployment)
    const mintpadERC1155Collection = await MintpadERC1155Collection.deploy();

    // Log the contract address
    console.log("MintpadERC1155Collection deployed to:", mintpadERC1155Collection.address);

    // Initialize the contract with your parameters
    // Replace with your actual values
    const maxSupply = 10000; // Example maximum supply
    const baseTokenURI = "https://api.example.com/tokens/"; // Example base URI
    const preRevealURI = "https://api.example.com/pre-reveal.json"; // Example pre-reveal URI
    const saleRecipient = deployer.address; // Address to receive sale proceeds
    const royaltyRecipients = [deployer.address]; // Example royalty recipient
    const royaltyShares = [10000]; // Example royalty share (100%)
    const royaltyPercentage = 500; // Example royalty percentage (5%)

    // Initialize the contract
    const tx = await mintpadERC1155Collection.initialize(
        "My ERC1155 Collection", // Collection name
        "MERC1155", // Collection symbol
        maxSupply,
        baseTokenURI,
        preRevealURI,
        saleRecipient,
        royaltyRecipients,
        royaltyShares,
        royaltyPercentage,
        deployer.address // Set the deployer as the owner
    );

    // Wait for the transaction to be mined
    await tx.wait();

    console.log("MintpadERC1155Collection initialized successfully.");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
