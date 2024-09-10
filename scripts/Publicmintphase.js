const { ethers } = require("hardhat");

async function main() {
    const collectionAddress = "0x0890412878Ba3916D7b8Da01944302d8479A2088"; // Replace with your contract address
    const collection = await ethers.getContractAt("MintpadERC721Collection", collectionAddress);

    const mintPhase = 1; // Public phase index
    const supply = 1000;
    const mintLimit = 5;
    const mintPrice = ethers.parseEther("0.00001");
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const mintDuration = 7 * 24 * 60 * 60; // 7 days
    const mintEndTime = currentTimestamp + mintDuration;

    const tx = await collection.setMintPhaseSettings(
        mintPhase,
        supply,
        mintLimit,
        mintPrice,
        currentTimestamp, // Start time
        mintEndTime // End time
    );

    console.log("Transaction sent:", tx.hash);
    const receipt = await tx.wait();
    console.log("Public mint phase set. Transaction receipt:", receipt);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
