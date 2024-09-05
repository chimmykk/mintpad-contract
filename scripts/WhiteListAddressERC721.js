const { ethers } = require("hardhat");

async function main() {
  const collectionAddress = "0x3d952a2F6e5cC470a5a4d4e91f9aeb29b77c8413"; // Replace with your contract address

  // Get signer (deployer)
  const [signer] = await ethers.getSigners();
  const collectionContract = await ethers.getContractAt("MintpadERC721Collection", collectionAddress);

  // Step 1: Set Whitelist Mint Phase
  const mintStartTime = Math.floor(Date.now() / 1000); // Current time in seconds
  const mintEndTime = mintStartTime + 3600 * 24 * 7; // Whitelist phase for 1 week (in seconds)
  const mintPhase = 2; // 2 represents the Whitelist phase in your contract's enum
  const phaseSupply = 1000; // Set the supply for the Whitelist phase
  const phaseMintPrice = ethers.parseEther("0.03"); // Set the mint price (0.03 ETH for whitelist)
  const phaseMintLimit = 2; // Maximum mints allowed per address during Whitelist phase

  console.log("Setting mint phase to Whitelist...");

  const txSetPhase = await collectionContract.connect(signer).setMintPhase(
    mintStartTime,
    mintEndTime,
    mintPhase,
    phaseSupply,
    phaseMintPrice,
    phaseMintLimit
  );

  await txSetPhase.wait();
  console.log("Whitelist mint phase set successfully!");

  // Step 2: Set whitelist addresses (example)
  const whitelistAddresses = ["0xYourWhitelistAddress1", "0xYourWhitelistAddress2"]; // Replace with real addresses

  console.log("Setting whitelist addresses...");
  const txSetWhitelist = await collectionContract.connect(signer).setWhitelist(whitelistAddresses, true);
  await txSetWhitelist.wait();
  console.log("Whitelist addresses set successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error setting whitelist phase:", error);
    process.exit(1);
  });
