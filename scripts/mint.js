const { ethers } = require("hardhat");

async function main() {
  // Replace with the actual address of the deployed ERC-721 collection contract
  const collectionAddress = "0xbd9514F3BaF68bC494463f7079F88E67210c4559";

  // Define the token ID you want to mint (e.g., token ID 1)
  const tokenId = 1;

  // Get the signer who will be minting the token
  const [signer] = await ethers.getSigners();

  // Set up the collection contract instance
  const collectionContract = await ethers.getContractAt("MintpadERC721Collection", collectionAddress);

  // Define the mint price (must match the mint price in the contract)
  const mintPrice = await collectionContract.mintPrice();

  // Send the transaction to mint the token
  const tx = await collectionContract.connect(signer).mint(tokenId, {
    value: mintPrice, // Send the correct mint price in the transaction
  });

  // Wait for the transaction to be mined
  console.log("Minting transaction sent:", tx.hash);
  const receipt = await tx.wait();

  console.log(`Token ID ${tokenId} minted successfully!`);
  console.log("Transaction receipt:", receipt);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error minting token:", error);
    process.exit(1);
  });
