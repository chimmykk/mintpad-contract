const { ethers, upgrades } = require("hardhat");

async function main() {
    const name = "Mintpad Collection";
    const symbol = "MPC";
    const maxSupply = 10000;
    const baseTokenURI = "https://api.mintpad.com/metadata/";
    const preRevealURI = "https://api.mintpad.com/pre-reveal.json";
    const saleRecipient = "0xDCC84F30Fac85f5E8f7Dcf80B154A05AD25d2824";
    const royaltyRecipients = [
        "0xDCC84F30Fac85f5E8f7Dcf80B154A05AD25d2824", 
        "0xecA86f60212d55C64E82e906881eD375d237f025"
    ];
    const royaltyShares = [5000, 5000];
    const royaltyPercentage = 500;
    const owner = "0xecA86f60212d55C64E82e906881eD375d237f025";

    const MintpadERC721Collection = await ethers.getContractFactory("MintpadERC721Collection");

    // Deploy using the upgrades plugin
    const mintpadERC721Collection = await upgrades.deployProxy(MintpadERC721Collection, [
        name,
        symbol,
        maxSupply,
        baseTokenURI,
        preRevealURI,
        owner,
        saleRecipient,
        royaltyRecipients,
        royaltyShares,
        royaltyPercentage
    ], { initializer: 'initialize' });

    await mintpadERC721Collection.deployed();

    console.log("MintpadERC721Collection deployed to:", mintpadERC721Collection.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
