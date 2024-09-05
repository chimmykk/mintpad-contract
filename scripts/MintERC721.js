const { ethers } = require("hardhat");

async function main() {
  const collectionAddress = "0x3d952a2F6e5cC470a5a4d4e91f9aeb29b77c8413"; 
  const tokenId = 0;


  const [signer] = await ethers.getSigners();
  const collectionContract = await ethers.getContractAt("MintpadERC721Collection", collectionAddress);


  const mintPrice = await collectionContract.mintPrice(); // Get the current mint price from the contract

  console.log(`Minting token with ID ${tokenId}...`);
  const txMint = await collectionContract.connect(signer).mint(tokenId, {
    value: mintPrice, // Send the correct amount of ETH for minting
  });
  console.log("Minting transaction sent:", txMint.hash);

  // Wait for the transaction to be confirmed
  const receipt = await txMint.wait();
  console.log(`Token ID ${tokenId} minted successfully!`);

  // Step 2: Retrieve the token URI
  const tokenURI = await collectionContract.tokenURI(tokenId);
  console.log(`Token URI for token ID ${tokenId}: ${tokenURI}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error in minting token:", error);
    process.exit(1);
  });
