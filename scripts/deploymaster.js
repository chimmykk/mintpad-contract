// scripts/deploy.js
const { ethers, upgrades } = require("hardhat");

async function main() {
    // Compile the contracts
    await hre.run('compile');

    // Deploy the MintpadERC721Collection contract
    const MintpadERC721Collection = await ethers.getContractFactory("MintpadERC721Collection");
    const mintpadERC721Collection = await upgrades.deployProxy(MintpadERC721Collection, {
        initializer: 'initialize',
    });
    await mintpadERC721Collection.deployed();
    
    console.log("MintpadERC721Collection deployed to:", mintpadERC721Collection.address);

    // Deploy the MintpadERC721CollectionFactory contract with the address of the MintpadERC721Collection implementation
    const MintpadERC721CollectionFactory = await ethers.getContractFactory("MintpadCollectionFactory");
    const mintpadERC721CollectionFactory = await MintpadERC721CollectionFactory.deploy(mintpadERC721Collection.address);
    await mintpadERC721CollectionFactory.deployed();

    console.log("MintpadERC721CollectionFactory deployed to:", mintpadERC721CollectionFactory.address);
}

// Execute the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
