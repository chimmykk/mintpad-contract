const { ethers } = require("hardhat");

async function main() {

  const collectionAddress = "0x82E7dceC78eF16ccDD803EcE15589660a7f065A0";

  const currentTimestamp = Math.floor(Date.now() / 1000);

  const mintDuration = 7 * 24 * 60 * 60; 
  const mintEndTime = currentTimestamp + mintDuration;
  const [owner] = await ethers.getSigners();

 
  const collectionContract = await ethers.getContractAt("MintpadERC721Collection", collectionAddress);

  const tx = await collectionContract.connect(owner).setMintPhase(currentTimestamp, mintEndTime);


  console.log("Updating mint phase transaction sent:", tx.hash);
  await tx.wait();

  console.log(`Mint phase set successfully! Minting starts at ${currentTimestamp} and ends at ${mintEndTime}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error setting mint phase:", error);
    process.exit(1);
  });
