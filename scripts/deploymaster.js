async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying contracts with account: ${deployer.address}`);
    
    const MintpadCollectionFactory = await ethers.getContractFactory("MintpadCollectionFactory");
    const factory = await MintpadCollectionFactory.deploy();

    console.log(`Factory deployed at: ${factory.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
