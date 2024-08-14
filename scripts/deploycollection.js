const { ethers } = require("hardhat");

async function main() {
  // Define the contract's factory address (already deployed)
  const factoryAddress = "0x8E5be506136ffFC6273257f0E02e67c3c2777A08";
  
  // Define the parameters for the collection
  const name = "MyNFTCollection";
  const symbol = "MNC";
  const mintPrice = ethers.parseEther("0.05"); // 0.05 ETH mint price
  const maxSupply = 10000;
  const baseURI = "https://example.com/metadata/";
  const recipient = "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a"; // Replace with the actual recipient address
  const royaltyRecipient = "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a"; // Replace with the actual royalty recipient address
  const royaltyPercentage = 500; // 5% royalties (500 basis points)

  // Connect to the deployed factory contract
  const factory = await ethers.getContractAt("MintPadERC721Factory", factoryAddress);

  // Ensure the factory contract requires a platform fee
  const platformFee = await factory.PLATFORM_FEE(); // Hardcoded to 0.00038 ETH

  // Deploy the collection by sending the required platform fee
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

  console.log("Transaction sent: ", tx.hash);

  // Wait for the transaction to be mined
  const receipt = await tx.wait();

  console.log("Collection deployed at: ", receipt.events[0].args.collectionAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
