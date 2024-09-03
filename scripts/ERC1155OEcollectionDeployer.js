const { ethers } = require("hardhat");

async function main() {
 
    const factoryAddress = "0x5caAde35832e814C52E0a6bE8115cf881Be072A3";
    const collectionName = "My ERC1155 Open Edition Collection"; // Replace with your desired collection name
    const collectionSymbol = "MYERC1155OPEN"; // Replace with your desired collection symbol
    const baseTokenURI = "ipfs://bafybeiafuvw7zyjo3kmeok6i4lkfwungtp4rzirng6j4vkispln7vp64xi/"; // Replace with your base URI
    const mintPrice = ethers.parseEther("0.00001"); // 0.00001 ETH mint price
    const recipient = "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a"; // Replace with the actual recipient address
    const openEditionDuration = 7 * 24 * 60 * 60; // 1 week in seconds

    const factory = await ethers.getContractAt("MintPadERC1155OpenEditionFactory", factoryAddress);
    const platformFee = await factory.PLATFORM_FEE();
    const tx = await factory.deployERC1155OpenEdition(
        collectionName,
        collectionSymbol,
        baseTokenURI,
        mintPrice,
        recipient,
        openEditionDuration,
        { value: platformFee }
    );

    console.log("Transaction sent:", tx.hash);
    const receipt = await tx.wait();
    const collectionAddress = receipt.events.find(event => event.event === "ERC1155OpenEditionDeployed").args.collectionAddress;
    console.log("ERC1155 Open Edition Collection deployed at:", collectionAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
