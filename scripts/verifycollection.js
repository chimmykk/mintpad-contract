const { run } = require("hardhat");

async function main() {
  const contractAddress = "0xbd9514F3BaF68bC494463f7079F88E67210c4559"; // Replace with deployed collection address


  const args = [
    "MyNFTCollection", // name
    "MNC", // symbol
    ethers.parseEther("0.05").toString(), // mintPrice (0.05 ETH)
    10000, // maxSupply
    "https://example.com/metadata/", // baseTokenURI
    "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a", // recipient address for minting funds
    "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a", // royalty recipient address
    500, // royaltyPercentage 
    "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a" // owner address
  ];

  try {

    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
    console.log("Contract verified successfully!");
  } catch (error) {
    console.error("Error verifying contract:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
