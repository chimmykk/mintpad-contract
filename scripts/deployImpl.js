const { ethers } = require("hardhat");

async function main() {
    const ERC721Implementation = await ethers.getContractFactory("MintpadERC721Collection");
    const erc721Implementation = await ERC721Implementation.deploy();

    console.log("ERC721 Implementation deployed to:", erc721Implementation);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
