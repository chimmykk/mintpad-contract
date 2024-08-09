const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTCollection and MasterNFTFactory Deployment", function () {
  let deployer;
  let masterNFTFactory;
  let nftCollection;
  let MasterNFTFactory;
  let NFTCollection;

  before(async function () {
    [deployer] = await ethers.getSigners();
    MasterNFTFactory = await ethers.getContractFactory("MasterNFTFactory");
    NFTCollection = await ethers.getContractFactory("NFTCollection");
  });

  it("should deploy MasterNFTFactory successfully", async function () {
    masterNFTFactory = await MasterNFTFactory.deploy();
    await masterNFTFactory.waitForDeployment();
    console.log("MasterNFTFactory deployed to:", masterNFTFactory.target);
    expect(masterNFTFactory.target).to.be.properAddress;
  });

  it("should deploy NFTCollection successfully", async function () {
    const name = "MyNFTCollection";
    const symbol = "MNFT";
    const mintPrice = ethers.parseUnits("0.01", "ether");
    const maxSupply = 1000;
    const baseURI = "https://example.com/api/";
    const recipient = deployer.address;
    const developerFee = ethers.parseUnits("0.001", "ether");

    nftCollection = await NFTCollection.deploy(
      name,
      symbol,
      mintPrice,
      maxSupply,
      baseURI,
      recipient,
      developerFee,
      deployer.address
    );
    await nftCollection.waitForDeployment();
    console.log("NFTCollection deployed to:", nftCollection.target);

    // to Verify the deployment
    expect(nftCollection.target).to.be.properAddress;
  });
});
