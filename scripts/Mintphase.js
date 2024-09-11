const { ethers } = require("hardhat");

async function main() {
  // Address of the deployed ERC721 collection
  const contractAddress = "0x12A36080248184036bc066C72d55dBe269e46f8d"; // Replace with your deployed contract address

  // Parameters for the mint phase
  const mintPrice = ethers.parseEther("0.01"); // Mint price 0.01 ETH
  const mintLimit = 2; // Mint limit per wallet
  const mintStartTime = Math.floor(Date.now() / 1000); // Current time in seconds
  const mintEndTime = mintStartTime + 7 * 24 * 60 * 60; // 1 week from now
  const whitelistEnabled = false; // Public mint phase

  // Get the contract instance
  const [deployer] = await ethers.getSigners();
  const contract = await ethers.getContractAt("MintpadERC721Collection", contractAddress);

  // Add the mint phase
  try {
    const tx = await contract.addMintPhase(
      mintPrice,
      mintLimit,
      mintStartTime,
      mintEndTime,
      whitelistEnabled
    );
    
    console.log("Transaction sent:", tx.hash);
    
    // Wait for the transaction to be mined
    const receipt = await tx.wait();
    
    console.log("Public mint phase added successfully!");
  } catch (error) {
    console.error("Error adding mint phase:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
