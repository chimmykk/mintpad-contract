const { ethers } = require("hardhat");

async function main() {
  // Address of the deployed ERC721 collection
  const contractAddress = "0x12A36080248184036bc066C72d55dBe269e46f8d"; // Replace with your deployed contract address

  // Get the contract instance
  const [deployer] = await ethers.getSigners();
  const contract = await ethers.getContractAt("MintpadERC721Collection", contractAddress);

  // Get total number of phases
  const totalPhases = await contract.getTotalPhases();
  console.log(`Total Phases: ${totalPhases}`);

  // Retrieve and display each phase
  for (let i = 0; i < totalPhases; i++) {
    const [mintPrice, mintLimit] = await contract.getPhase(i);
    console.log(`Phase ${i}:`);
    console.log(`  Mint Price: ${ethers.formatEther(mintPrice)} ETH`);
    console.log(`  Mint Limit: ${mintLimit}`);

  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
