// scripts/deployERC721.js

const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying ERC721 Collection with the account:", deployer.address);

    const MintpadERC721Collection = await ethers.getContractFactory("MintpadERC721Collection");
    const mintpadERC721Collection = await MintpadERC721Collection.deploy();

    console.log("MintpadERC721Collection deployed to:", mintpadERC721Collection.address);

    // Optionally, you can initialize it here if you want
    // Replace with your actual values
    const maxSupply = 1000;
    const baseTokenURI = "https://api.example.com/tokens/";
    const preRevealURI = "https://api.example.com/pre-reveal.json";
    const owner = deployer.address;
    const saleRecipient = deployer.address; // Replace with actual sale recipient if needed
    const royaltyRecipients = [deployer.address]; // Example
    const royaltyShares = [10000]; // Example (100% for the single recipient)
    const royaltyPercentage = 500; // Example (5%)

    const tx = await mintpadERC721Collection.initialize(
        "My NFT Collection", "MNFT", maxSupply, baseTokenURI, preRevealURI, owner, saleRecipient, royaltyRecipients, royaltyShares, royaltyPercentage
    );
    await tx.wait(); // Wait for the transaction to be mined

    console.log("MintpadERC721Collection initialized.");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
