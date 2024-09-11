const { run, ethers } = require("hardhat");

async function main() {
  const contractAddress = "0x12A36080248184036bc066C72d55dBe269e46f8d"; // Replace with deployed collection address

  const args = [
    "MyNFTCollection", // name
    "MNC", // symbol
    10000, // maxSupply
    "ipfs://bafybeiafuvw7zyjo3kmeok6i4lkfwungtp4rzirng6j4vkispln7vp64xi/", // baseURI
    "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a", // recipient address
    "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a", // royalty recipient address
    500, // royaltyPercentage
    "0xbEc50cA74830c67b55CbEaf79feD8517E9d9b3B2" // owner address
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
