// scripts/MasterImpl.js
const { ethers } = require("hardhat");

async function main() {
    const erc721Implementation = "0xD7196365cb9528DE0f06c43F4B02AF93D6B65877"; // ERC721 implementation address
    const erc1155Implementation = "0x407E678F66Dd4F481F0655DAD1125d54fa735F79"; // ERC1155 implementation address

    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const MintpadCollectionFactory = await ethers.getContractFactory("MintpadCollectionFactory");

    // Set platform addresses (at least one required)
    const platformAddresses = [deployer.address]; // Example platform address
    const platformFee = ethers.parseEther("0.01"); // Set platform fee (1 Ether for example)

    // Deploy the factory contract
    const factoryContract = await MintpadCollectionFactory.deploy(
        erc721Implementation,
        erc1155Implementation,
        platformAddresses,
        platformFee
    );

    await factoryContract.deployed();

    console.log("MintpadCollectionFactory deployed to:", factoryContract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
