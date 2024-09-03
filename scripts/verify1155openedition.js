const { run, ethers } = require("hardhat");

async function main() {
    const contractAddress = "0xDAfcA5F73806f62B29b019E4d293Da9063dB00dd";

    // Constructor arguments used during deployment
    const args = [
        "My ERC1155 Open Edition Collection", // collectionName
        "MYERC1155OPEN", // collectionSymbol
        "ipfs://bafybeiafuvw7zyjo3kmeok6i4lkfwungtp4rzirng6j4vkispln7vp64xi/", // baseTokenURI
        ethers.parseEther("0.00001"), // mintPrice
        "0x68EB182aF9DC1e818798F5EA75F061D9cA7CC76a", // recipient
        7 * 24 * 60 * 60,// openEditionDuration (1 week in seconds)
        "0xbEc50cA74830c67b55CbEaf79feD8517E9d9b3B2" // address of the contract owner


    ];

    console.log("Verifying contract...");

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
