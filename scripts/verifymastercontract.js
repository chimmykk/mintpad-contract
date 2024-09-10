const { ethers, run } = require("hardhat");

async function main() {
  const contractAddress = "0x28B3a7c0f335124DC8c9402FbF6ddA937a95fE2A"; 

  console.log("Verifying contract at address:", contractAddress);

  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: [],
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
