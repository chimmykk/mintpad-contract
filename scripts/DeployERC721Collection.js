const { ethers } = require("hardhat");

async function main() {
  // The factory contract address
  const factoryAddress = "0xc0a00fafc52a092ecb43baa6a93ad2f5e98c661c";

  // Define the parameters for the new NFT collection
  const collectionName = "MyNFTCollection";
  const collectionSymbol = "MNC";
  const mintPrice = ethers.parseEther("0.00001"); // 0.00001 ETH mint price
  const maxSupply = 10000;
  const baseTokenURI = "ipfs://bafybeiafuvw7zyjo3kmeok6i4lkfwungtp4rzirng6j4vkispln7vp64xi/";
  const recipient = "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a"; // Replace with the actual recipient address
  const royaltyRecipient = "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a"; // Replace with the actual royalty recipient address
  const royaltyPercentage = 500; // 5% royalties

  // Get the factory contract instance
  const factory = await ethers.getContractAt("MintPadERC721Factory", factoryAddress);

  // Retrieve the platform fee from the factory contract
  const platformFee = await factory.PLATFORM_FEE();

  // Deploy a new collection with the specified parameters
  const tx = await factory.deployCollection(
    collectionName,
    collectionSymbol,
    mintPrice,
    maxSupply,
    baseTokenURI,
    recipient,
    royaltyRecipient,
    royaltyPercentage,
    { value: platformFee }
  );

  console.log("Transaction sent:", tx.hash);

  // Wait for the transaction to be mined
  const receipt = await tx.wait();

  // Extract and log the deployed collection's address from the event logs
  const collectionAddress = receipt.events.find(event => event.event === 'CollectionDeployed').args.collectionAddress;
  console.log("Collection deployed at:", collectionAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });