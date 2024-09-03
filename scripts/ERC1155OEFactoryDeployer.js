const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Compile and deploy the contract
    const ERC1155Factory = await ethers.getContractFactory("MintPadERC1155OpenEditionFactory");
    const erc1155Factory = await ERC1155Factory.deploy();

    console.log("MintPadERC1155OpenEditionFactory deployed to:", erc1155Factory);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
