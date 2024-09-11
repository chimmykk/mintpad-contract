const { ethers } = require("hardhat");

async function main() {
  // Address of the deployed ERC721 collection
  const contractAddress = "0x12A36080248184036bc066C72d55dBe269e46f8d"; // Replace with your deployed contract address

  // Get the contract instance
  const [deployer] = await ethers.getSigners();
  const contract = await ethers.getContractAt("MintpadERC721Collection", contractAddress);

  // Get current time and calculate the end time (one week from now)
  const currentTime = Math.floor(Date.now() / 1000); // Current time in Unix timestamp
  const oneWeekLater = currentTime + (7 * 24 * 60 * 60); // One week later in Unix timestamp

  // Parameters for the new mint phase
  const mintPrice = ethers.parseEther("0.0001"); // Example mint price of 0.02 ETH
  const mintLimit = 20; // Example mint limit
  const mintStartTime = currentTime; // Start time now
  const mintEndTime = oneWeekLater; // End time one week from now
  const whitelistEnabled = true; // Enable whitelist for this phase

  // Add the new mint phase
  console.log("Adding new mint phase...");
  const txAddPhase = await contract.addMintPhase(
    mintPrice,
    mintLimit,
    mintStartTime,
    mintEndTime,
    whitelistEnabled
  );
  console.log(`Mint phase transaction hash: ${txAddPhase.hash}`);

  // Wait for the transaction to be mined
  const receiptAddPhase = await txAddPhase.wait();
  console.log(`Mint phase transaction confirmed in block ${receiptAddPhase.blockNumber}`);

  // List of whitelist addresses
  const whitelistAddresses = [
    "0xbEc50cA74830c67b55CbEaf79feD8517E9d9b3B2", // Replace with actual whitelist addresses
    "0xDCC84F30Fac85f5E8f7Dcf80B154A05AD25d2824",
  ];

  // Set whitelist addresses
  console.log("Setting whitelist addresses...");
  const txSetWhitelist = await contract.setWhitelist(whitelistAddresses, true);
  console.log(`Whitelist transaction hash: ${txSetWhitelist.hash}`);

  // Wait for the transaction to be mined
  const receiptSetWhitelist = await txSetWhitelist.wait();
  console.log(`Whitelist transaction confirmed in block ${receiptSetWhitelist.blockNumber}`);

  console.log("Mint phase and whitelist addresses updated successfully.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
