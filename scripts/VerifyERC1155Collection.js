const { run, ethers } = require("hardhat");

async function main() {
  const contractAddress = "0xe2BEF47b899691C45103Da6c8B553Ab803474762"; // Replace with your contract address

  // The constructor arguments used when deploying the contract
  const args = [
    "MyERC1155Collection",
    "MERC",
    "ipfs://bafybeiafuvw7zyjo3kmeok6i4lkfwungtp4rzirng6j4vkispln7vp64xi/", // baseTokenURI
    ethers.parseEther("0.00001"), // mintPrice (0.00001 ETH)
    10000, // maxSupply
    "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a", // recipient address for minting funds
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
