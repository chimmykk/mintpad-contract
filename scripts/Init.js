async function main() {
    const [] = await ethers.getSigners();
    const factoryAddress = "0x895aA2a45b30b1979AaC913D2162b719554b9a9C";
    const Factory = await ethers.getContractFactory("MintPadCollectionFactory");
    const factory = await Factory.attach(factoryAddress);
    await factory.initialize();
    console.log("Contract initialized");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
