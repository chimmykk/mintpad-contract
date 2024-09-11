const { ethers } = require("hardhat");

async function main() {
  // Define the master contract (factory)
  const factoryAddress = "0x895aA2a45b30b1979AaC913D2162b719554b9a9C";

  // Define the parameters for the new NFT collection
  const name = "MyNFTCollection";
  const symbol = "MNC";
  const maxSupply = 10000;
  const baseURI = "ipfs://bafybeiafuvw7zyjo3kmeok6i4lkfwungtp4rzirng6j4vkispln7vp64xi/";
  const recipient = "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a"; // Replace with the actual recipient address
  const royaltyRecipient = "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a"; // Replace with the actual royalty recipient address
  const royaltyPercentage = 500; // 5% royalties

  // Get the factory contract instance
  const factory = await ethers.getContractAt("MintPadCollectionFactory", factoryAddress);

  // Retrieve the platform fee from the factory contract
  const platformFee = await factory.platformFee(); // Access platformFee as a public variable

  // Deploy a new ERC721 collection with the specified parameters
  const tx = await factory.deployCollection(
    name,
    symbol,
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
  const collectionAddress = receipt.events.find(event => event.event === 'CollectionDeployed').args.collectionAddress;
  console.log("Collection deployed at:", collectionAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
