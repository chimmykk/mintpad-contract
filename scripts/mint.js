const { ethers } = require("hardhat");

async function main() {
  // Address of the deployed ERC721 collection
  const contractAddress = "0xb0aab7d4f1d83f6b601baa3e68170b6c4c6261d4"; // Replace with your deployed contract address

  const [deployer] = await ethers.getSigners();
  const contract = await ethers.getContractAt("MintpadERC721Collection", contractAddress);

  const totalPhases = await contract.getTotalPhases();
  console.log(`Total Phases: ${totalPhases}`);

  for (let i = 0; i < totalPhases; i++) {
    const [mintPrice, mintLimit] = await contract.getPhase(i);
    console.log(`Phase ${i}:`);
    console.log(`  Mint Price: ${ethers.formatEther(mintPrice)} ETH`);
    console.log(`  Mint Limit: ${mintLimit}`);

  }

  const phaseIndex = 0;
  const tokenId = 1;

  const [mintPrice] = await contract.getPhase(phaseIndex);

  // Convert mint price to a format suitable for the transaction
  const mintPriceInEther = ethers.formatEther(mintPrice);
  const value = ethers.parseEther(mintPriceInEther);

  // Perform the mint transaction
  const tx = await contract.mint(phaseIndex, tokenId, {
    value: value,
  });

  console.log(`Minting transaction sent: ${tx.hash}`);

  const receipt = await tx.wait();
  console.log(`Minting transaction confirmed in block ${receipt.blockNumber}`);

  const tokenURI = await contract.tokenURI(tokenId);
  console.log(`Token URI for token ID ${tokenId}: ${tokenURI}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
