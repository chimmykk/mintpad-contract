const { ethers } = require("hardhat");

async function main() {
  // Replace with the actual address of the deployed ERC-721 collection contract
  const collectionAddress = "0xbd9514F3BaF68bC494463f7079F88E67210c4559";

  // Get the current timestamp (in seconds)
  const currentTimestamp = Math.floor(Date.now() / 1000);

  // Define the mint end time as one week from now (7 * 24 * 60 * 60 seconds)
  const mintDuration = 7 * 24 * 60 * 60; // 1 week
  const mintEndTime = currentTimestamp + mintDuration;

  // Get the signer (the owner of the contract)
  const [owner] = await ethers.getSigners();

  // Connect to the deployed collection contract
  const collectionContract = await ethers.getContractAt("MintpadERC721Collection", collectionAddress);

  // Call the setMintPhase function with current timestamp as start time and 1 week later as end time
  const tx = await collectionContract.connect(owner).setMintPhase(currentTimestamp, mintEndTime);

  // Wait for the transaction to be mined
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
