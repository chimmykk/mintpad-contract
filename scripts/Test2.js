// scripts/deploy.js
const { ethers, upgrades } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Contract initialization parameters
    const name = "Mintpad ERC1155 Collection";
    const symbol = "MPC1155";
    const maxSupply = 10000;  // Max supply for each token
    const baseTokenURI = "https://api.mintpad.com/metadata/";  // Base metadata URI
    const preRevealURI = "https://api.mintpad.com/pre-reveal.json";  // Pre-reveal metadata URI
    const saleRecipient = "0xYourSaleRecipientAddress";  // Address to receive sale funds
    const royaltyRecipients = [
        "0xYourRoyaltyRecipient1",
        "0xYourRoyaltyRecipient2"
    ];  // Addresses for royalty recipients
    const royaltyShares = [5000, 5000];  // Royalty shares (e.g., 5000 = 50%)
    const royaltyPercentage = 500;  // Royalty percentage (5%)
    
    // Deploy the MintpadERC1155Collection contract as an upgradeable contract
    const MintpadERC1155Collection = await ethers.getContractFactory("MintpadERC1155Collection");
    const mintpadERC1155 = await upgrades.deployProxy(MintpadERC1155Collection, [
        name,
        symbol,
        maxSupply,
        baseTokenURI,
        preRevealURI,
        saleRecipient,
        royaltyRecipients,
        royaltyShares,
        royaltyPercentage,
        deployer.address // Owner of the contract
    ], { initializer: 'initialize' });

    await mintpadERC1155.deployed();

    console.log("MintpadERC1155Collection deployed to:", mintpadERC1155.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
