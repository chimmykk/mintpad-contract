const { ethers, run } = require("hardhat");

async function main() {
  const contractAddress = "0x438191e080124D14355b69A1352dcc22517493Cc"; 

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