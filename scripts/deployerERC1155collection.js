const { ethers } = require("hardhat");

async function main() {
  // Define the master contract (factory) address for ERC1155
  const factoryAddress = "0xFB28574be91719d14CfFE61Ba9fd89bd5B60A101"; // Replace with your ERC1155 factory contract address
  
  // Define the parameters for the new ERC1155 collection
  const collectionName = "MyERC1155Collection";
  const collectionSymbol = "MERC1155";
  const baseTokenURI = "ipfs://bafybeiafuvw7zyjo3kmeok6i4lkfwungtp4rzirng6j4vkispln7vp64xi/";
  const mintPrice = ethers.parseEther("0.00001"); // 0.00001 ETH mint price
  const maxSupply = 10000; // Maximum supply for the ERC1155 collection
  const recipient = "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a"; // Replace with the actual recipient address
  const royaltyRecipient = "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a"; // Replace with the actual royalty recipient address
  const royaltyPercentage = 500; // 5% royalties

  // Get the factory contract instance
  const factory = await ethers.getContractAt("MintPadCollectionFactory", factoryAddress);

  // Retrieve the platform fee from the factory contract
  const platformFee = await factory.PLATFORM_FEE();

  // Deploy a new ERC1155 collection with the specified parameters
  const tx = await factory.deployERC1155Collection(
    collectionName,
    collectionSymbol,
    baseTokenURI,
    mintPrice,
    maxSupply,
    recipient,
    royaltyRecipient,
    royaltyPercentage,
    { value: platformFee }
  );

  console.log("Transaction sent:", tx.hash);

  // Wait for the transaction to be mined
  const receipt = await tx.wait();

  // Extract and log the deployed collection's address from the event logs
  const collectionAddress = receipt.events.find(event => event.event === "ERC1155CollectionDeployed").args.collectionAddress;
  console.log("ERC1155 Collection deployed at:", collectionAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
