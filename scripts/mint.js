const { ethers } = require("hardhat");

async function main() {

  const collectionAddress = "0x480B23F530cD7a3b7da9EcE28ad2fC6B6c7E7E4b";

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
