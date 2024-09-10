const { run, ethers } = require("hardhat");

async function main() {
  const contractAddress = "0xb012032613E957c13acC3b806bE4E60f6Fc0e701"; // Replace with deployed collection address

  const args = [
    "MyNFTCollection", // name
    "MNC", // symbol
    ethers.parseEther("0.00001"), // mintPrice (0.00001 ETH)
    10000, // maxSupply
    "ipfs://bafybeiafuvw7zyjo3kmeok6i4lkfwungtp4rzirng6j4vkispln7vp64xi/", // baseTokenURI
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
