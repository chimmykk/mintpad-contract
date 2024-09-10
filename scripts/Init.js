async function main() {
    const [] = await ethers.getSigners();
    const factoryAddress = "0x6983E0be213e44a39bAf5905fc376c8868d2Be3a";
    const Factory = await ethers.getContractFactory("MintPadCollectionFactory");
    const factory = await Factory.attach(factoryAddress);
    
    // Initialize the contract
    await factory.initialize();
    console.log("Contract initialized");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
