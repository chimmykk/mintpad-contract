const { ethers } = require("hardhat");

async function main() {

  const collectionAddress = "0x82E7dceC78eF16ccDD803EcE15589660a7f065A0";

  const tokenId = 0;


  const [signer] = await ethers.getSigners();
  const collectionContract = await ethers.getContractAt("MintpadERC721Collection", collectionAddress);
  const mintPrice = await collectionContract.mintPrice();

  const tx = await collectionContract.connect(signer).mint(tokenId, {
    value: mintPrice, 
  });
  console.log("Minting transaction sent:", tx.hash);
  const receipt = await tx.wait();

  console.log(`Token ID ${tokenId} minted successfully!`);


  const tokenURI = await collectionContract.tokenURI(tokenId);
  console.log(`Token URI for token ID ${tokenId}: ${tokenURI}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error minting token:", error);
    process.exit(1);
  });
