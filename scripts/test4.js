const { ethers } = require("hardhat");

async function main() {
    // Get the signers
    const [deployer] = await ethers.getSigners();

    // Factory contract address
    const factoryAddress = "0xef24FEf5d5F7B58802a7bFF049c2879070D7Bb09";

    // Connect to the factory contract
    const MintpadCollectionFactory = await ethers.getContractFactory("MintpadCollectionFactory");
    const factory = MintpadCollectionFactory.attach(factoryAddress);

    // Set the parameters for the ERC721 collection
    const name = "My ERC721 Collection";
    const symbol = "MYERC721";
    const maxSupply = 1000;  // Set your desired maximum supply
    const baseURI = "https://my.api.com/metadata/";  // Set your base URI
    const owner = deployer.address;  // The deployer will be the owner
    const saleRecipient = deployer.address;  // Change if you want a different sale recipient
    const royaltyRecipients = [deployer.address];  // Array of royalty recipient addresses
    const royaltyShares = [10000];  // Array of royalty shares corresponding to recipients
    const royaltyPercentage = 500;  // Set your desired royalty percentage (e.g., 5% = 500)

    // Get the platform fee
    const platformFee = await factory.platformFee();

    // Deploy the ERC721 Collection
    const tx = await factory.deployERC721Collection(
        name,
        symbol,
        maxSupply,
        baseURI,
        owner,
        saleRecipient,
        royaltyRecipients,
        royaltyShares,
        royaltyPercentage,
        {
            value: platformFee,  // Pay the platform fee
        }
    );

    console.log(`Deploying ERC721 Collection... Transaction Hash: ${tx.hash}`);

    // Wait for the transaction to be mined
    await tx.wait();

    console.log(`ERC721 Collection deployed! Transaction successful: ${tx.hash}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
