// scripts/deployFactory.js

const { ethers, upgrades } = require("hardhat");

async function main() {
  // Step 1: Use the provided addresses for ERC721 and ERC1155 implementations
  const erc721Implementation = "0x1F275A4411B535Bd5367F927c18Eef32Cf6CbD30";
  const erc1155Implementation = "0x38c432389D2f70C0cec3e949a3fC84653ba79C97";

  console.log("Using ERC721 implementation address:", erc721Implementation);
  console.log("Using ERC1155 implementation address:", erc1155Implementation);

  // Step 2: Deploy the MintpadCollectionFactory with the implementation addresses
  console.log("Deploying MintpadCollectionFactory...");
  const MintpadCollectionFactory = await ethers.getContractFactory("MintpadCollectionFactory");
  const factory = await upgrades.deployProxy(MintpadCollectionFactory, [erc721Implementation, erc1155Implementation], {
    initializer: "initialize"
  });
  await factory.deployed();
  console.log("MintpadCollectionFactory deployed at:", factory.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
