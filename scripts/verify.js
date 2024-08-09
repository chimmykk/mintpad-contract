const { ethers, run } = require("hardhat");

async function main() {
  const contractAddress = "0x1dE3F5DF9A234D555df74C1A1b4375417a1e0e96"; // Replace with your MasterNFTFactory contract address

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

  const { ethers, run } = require("hardhat");

async function main() {
  const contractAddress = "0x9909Dd2BFd1f34A414fc56001B5C372f71c2391c"; // Replace with your NFTCollection contract address

  console.log("Verifying contract at address:", contractAddress);

  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: [
        "MyNFTCollection", // name
        "MNFT",            // symbol
        ethers.parseUnits("0.01", "ether"), // mintPrice
        1000,              // maxSupply
        "https://example.com/api/", // baseURI
        "0x54AFc632a75cc2A0939875F788c9757ee67c7f61", // recipient
        ethers.parseUnits("0.001", "ether"), // developerFee
        "0x54AFc632a75cc2A0939875F788c9757ee67c7f61"  // owner
      ],
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
