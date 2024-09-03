const { ethers, run } = require("hardhat");

async function main() {
  const contractAddress = "0x0841B86c1b9CE6B4F7abf327adD7DE8F8A3a9762"; // Replace with your MasterNFTFactory contract address

  console.log("Verifying contract at address:", contractAddress);

  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: [], // MasterNFTFactory does not have constructor arguments
    });
    console.log("Verification process completed.");
  } catch (error) {
    console.error("Verification failed:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Script failed:", error);
    process.exit(1);
  });

  //
