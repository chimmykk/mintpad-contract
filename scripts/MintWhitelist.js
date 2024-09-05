const { ethers } = require("hardhat");

async function main() {
  const collectionAddress = "0x3d952a2F6e5cC470a5a4d4e91f9aeb29b77c8413"; 
  const tokenId = 1; 

  const [signer] = await ethers.getSigners();
  const collectionContract = await ethers.getContractAt("MintpadERC721Collection", collectionAddress);

  const currentMintPhase = await collectionContract.currentMintPhase();
  if (currentMintPhase !== 2) { // 2 represents Whitelist phase in your enum
    console.log("Whitelist phase is not active. Please activate the whitelist phase.");
    return;
  }


  const isWhitelisted = await collectionContract.whitelist(signer.address);
  if (!isWhitelisted) {
    console.log("Your address is not whitelisted for this mint phase.");
    return;
  }

  // Step 3: Get the mint price
  const mintPrice = await collectionContract.mintPrice(); // Mint price for whitelist phase

  // Step 4: Mint a token
  console.log(`Minting token with ID ${tokenId}...`);

  const txMint = await collectionContract.connect(signer).mint(tokenId, {
    value: mintPrice, // Send the correct amount of ETH for minting
  });

  console.log("Minting transaction sent:", txMint.hash);
  const receipt = await txMint.wait();
  console.log(`Token ID ${tokenId} minted successfully!`);

  // Step 5: Retrieve and log the token URI
  const tokenURI = await collectionContract.tokenURI(tokenId);
  console.log(`Token URI for token ID ${tokenId}: ${tokenURI}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error in minting token during whitelist phase:", error);
    process.exit(1);
  });
