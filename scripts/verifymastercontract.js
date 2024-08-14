const { ethers, run } = require("hardhat");

async function main() {
  const contractAddress = "0xeb26D2c712da16b3651243e9774979842427411e"; // Replace with your MasterNFTFactory contract address

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
