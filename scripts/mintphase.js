const { ethers } = require("hardhat");

async function main() {
  const collectionAddress = "0xb012032613E957c13acC3b806bE4E60f6Fc0e701"; // Your collection address

  const currentTimestamp = Math.floor(Date.now() / 1000); // Current time in seconds
  const mintDuration = 7 * 24 * 60 * 60; // 7 days in seconds
  const mintEndTime = currentTimestamp + mintDuration;

  // Define the parameters for the mint phase
  const mintPhase = 1; // e.g., 1 for public mint (adjust as needed)
  const phaseSupply = 100; // Total number of tokens available during this phase
  const phaseMintPrice = "0.01"; // Price per token in ETH (convert to Wei below)
  const phaseMintLimit = 5; // Max number of tokens each address can mint

  const [owner] = await ethers.getSigners(); // Get the deployer account (owner)

  // Get the contract instance
  const collectionContract = await ethers.getContractAt("MintpadERC721Collection", collectionAddress);

  // Convert mint price to Wei (smallest unit of Ether)
  const mintPriceInWei = ethers.parseEther(phaseMintPrice);

  // Call the setMintPhase function with the updated parameters
  const tx = await collectionContract.connect(owner).setMintPhase(
    currentTimestamp, // Start time
    mintEndTime, // End time
    mintPhase, // Mint phase (public or whitelist, etc.)
    phaseSupply, // Phase supply
    mintPriceInWei, // Phase mint price in Wei
    phaseMintLimit // Mint limit per wallet
  );

  console.log("Updating mint phase transaction sent:", tx.hash);
  await tx.wait();

  console.log(`Mint phase set successfully! Minting starts at ${currentTimestamp} and ends at ${mintEndTime}`);
  console.log(`Mint phase details: Phase ${mintPhase}, Supply: ${phaseSupply}, Price: ${phaseMintPrice} ETH, Mint limit: ${phaseMintLimit} per wallet.`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error setting mint phase:", error);
    process.exit(1);
  });
