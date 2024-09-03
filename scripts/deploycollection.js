const { ethers } = require("hardhat");

async function main() {
  // Define the master contract (factory)
  const factoryAddress = "0x39bADC7850ac3D5b7E319C275600D04FA2834479";
  
  // Define the parameters for the new NFT collection
  const name = "MyNFTCollection";
  const symbol = "MNC";
  const mintPrice = ethers.parseEther("0.00001"); // 0.00001 ETH mint price
  const maxSupply = 10000;
  const baseURI = "ipfs://bafybeiafuvw7zyjo3kmeok6i4lkfwungtp4rzirng6j4vkispln7vp64xi/";
  const recipient = "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a"; // Replace with the actual recipient address
  const royaltyRecipient = "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a"; // Replace with the actual royalty recipient address
  const royaltyPercentage = 500; // 5% royalties 

  // Get the factory contract instance
  const factory = await ethers.getContractAt("MintPadCollectionFactory.sol", factoryAddress);

  // Retrieve the platform fee from the factory contract
  const platformFee = await factory.PLATFORM_FEE();

  // Deploy a new collection with the specified parameters
  const tx = await factory.deployCollection(
    name,
    symbol,
    mintPrice,
    maxSupply,
    baseURI,
    recipient,
    royaltyRecipient,
    royaltyPercentage,
    { value: platformFee }
  );

  console.log("Transaction sent:", tx.hash);

  // Wait for the transaction to be mined
  const receipt = await tx.wait();

  // Extract and log the deployed collection's address from the event logs
  const collectionAddress = receipt.events[0].args.collectionAddress;
  console.log("Collection deployed at:", collectionAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
