const { ethers } = require("hardhat");

async function main() {
  const collectionAddress = "0x3d952a2F6e5cC470a5a4d4e91f9aeb29b77c8413"; // Replace with your contract address

  // Get signer
  const [signer] = await ethers.getSigners();
  const collectionContract = await ethers.getContractAt("MintpadERC721Collection", collectionAddress);

  // Setting the mint phase to Public
  const mintStartTime = Math.floor(Date.now() / 1000); // Current time in seconds
  const mintEndTime = mintStartTime + 3600 * 24 * 7; // 1 week duration
  const mintPhase = 1; // 1 represents the Public phase
  const phaseSupply = 5000; // Set the supply for the Public phase
  const phaseMintPrice = ethers.parseEther("0.02"); // Set the mint price (0.05 ETH)
  const phaseMintLimit = 5; // Maximum mints allowed per address during Public phase

  console.log("Setting mint phase to Public...");
  const tx = await collectionContract.connect(signer).setMintPhase(
    mintStartTime,
    mintEndTime,
    mintPhase,
    phaseSupply,
    phaseMintPrice,
    phaseMintLimit
  );
  await tx.wait();
  console.log("Mint phase set to Public!");

  console.log(`Mint phase set from ${mintStartTime} to ${mintEndTime}`);
  console.log(`Supply: ${phaseSupply}`);
  console.log(`Mint price: ${ethers.utils.formatEther(phaseMintPrice)} ETH`);
  console.log(`Mint limit: ${phaseMintLimit} tokens per address`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error setting mint phase:", error);
    process.exit(1);
  });
