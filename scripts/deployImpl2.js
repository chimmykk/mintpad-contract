const { ethers } = require("hardhat");

async function main() {
    const ERC1155Implementation = await ethers.getContractFactory("MintpadERC1155Collection");
    const erc1155Implementation = await ERC1155Implementation.deploy();
    console.log("ERC1155 Implementation deployed to:", erc1155Implementation.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
