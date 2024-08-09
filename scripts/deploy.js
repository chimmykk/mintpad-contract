const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const MasterNFTFactory = await ethers.getContractFactory("MasterNFTFactory");
  const masterNFTFactory = await MasterNFTFactory.deploy();
  await masterNFTFactory.waitForDeployment(); 

  console.log("MasterNFTFactory deployed to:", masterNFTFactory.target); 

  const name = "MyNFTCollection";
  const symbol = "MNFT";
  const mintPrice = ethers.parseUnits("0.01", "ether"); 
  const maxSupply = 1000;
  const baseURI = "https://example.com/api/";
  const recipient = deployer.address; 
  const developerFee = ethers.parseUnits("0.001", "ether");
  const NFTCollection = await ethers.getContractFactory("NFTCollection");
  const nftCollection = await NFTCollection.deploy(
    name,
    symbol,
    mintPrice,
    maxSupply,
    baseURI,
    recipient,
    developerFee,
    deployer.address 
  );
  await nftCollection.waitForDeployment();

  console.log("NFTCollection deployed to:", nftCollection.target); 
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
