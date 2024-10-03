const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MintpadERC721Collection", function () {
    let MintpadERC721Collection;
    let mintpad;
    let owner, addr1, addr2, addr3;

    const maxSupply = 100;
    const baseTokenURI = "ipfs://testests/";
    const preRevealURI = "ipfs://testests/";
    const saleRecipient = "0x0000000000000000000000000000000000000001";
    const royaltyPercentage = 500; // 5%
    const royaltyRecipients = ["0x0000000000000000000000000000000000000002"];
    const royaltyShares = [1000]; // 1000 out of 10000

    beforeEach(async function () {
        [owner, addr1, addr2, addr3] = await ethers.getSigners();

        MintpadERC721Collection = await ethers.getContractFactory("MintpadERC721Collection");
        mintpad = await MintpadERC721Collection.deploy();
        await mintpad.initialize(
            "Test Token",
            "TT",
            maxSupply,
            baseTokenURI,
            preRevealURI,
            owner.address,
            saleRecipient,
            royaltyRecipients,
            royaltyShares,
            royaltyPercentage
        );
    });

    describe("Initialization", function () {
        it("should set the correct name and symbol", async function () {
            expect(await mintpad.name()).to.equal("Test Token");
            expect(await mintpad.symbol()).to.equal("TT");
        });

        it("should set the correct sale recipient", async function () {
            expect(await mintpad.saleRecipient()).to.equal(saleRecipient);
        });

        it("should set the correct royalty settings", async function () {
            expect(await mintpad.royaltyPercentage()).to.equal(royaltyPercentage);
            expect(await mintpad.royaltyRecipients(0)).to.equal(royaltyRecipients[0]);
        });
    });

    describe("Minting Phases", function () {
        it("should allow the owner to add a mint phase", async function () {
            const price = ethers.parseEther("0.1");
            const limit = 10;
            const startTime = Math.floor(Date.now() / 1000) + 60; // Starts in 1 minute
            const endTime = startTime + 3600; // Ends in 1 hour
            const whitelistEnabled = true;

            await mintpad.addMintPhase(price, limit, startTime, endTime, whitelistEnabled, []);
            const phase = await mintpad.getPhase(0);

            expect(phase.mintPrice).to.equal(price);
            expect(phase.mintLimit).to.equal(limit);
            expect(phase.mintStartTime).to.equal(startTime);
            expect(phase.mintEndTime).to.equal(endTime);
            expect(phase.whitelistEnabled).to.equal(whitelistEnabled);
        });

        it("should revert if non-owner tries to add a mint phase", async function () {
            const price = ethers.parseEther("0.1");
            const limit = 10;
            const startTime = Math.floor(Date.now() / 1000) + 60; // Starts in 1 minute
            const endTime = startTime + 3600; // Ends in 1 hour
            const whitelistEnabled = true;

            await expect(
                mintpad.connect(addr1).addMintPhase(price, limit, startTime, endTime, whitelistEnabled, [])
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("should revert if minting outside of phase time", async function () {
            const price = ethers.parseEther("0.1");
            const limit = 10;
            const startTime = Math.floor(Date.now() / 1000) + 60; // Starts in 1 minute
            const endTime = startTime + 3600; // Ends in 1 hour
            const whitelistEnabled = true;

            await mintpad.addMintPhase(price, limit, startTime, endTime, whitelistEnabled, []);

            await expect(
                mintpad.mint(0, 1, { value: price })
            ).to.be.revertedWith("Minting phase inactive");
        });

        it("should revert if mint price is incorrect", async function () {
            const price = ethers.parseEther("0.1");
            const limit = 10;
            const startTime = Math.floor(Date.now() / 1000) + 60; // Starts in 1 minute
            const endTime = startTime + 3600; // Ends in 1 hour
            const whitelistEnabled = true;

            await mintpad.addMintPhase(price, limit, startTime, endTime, whitelistEnabled, []);

            // Move time forward to within the minting phase
            await ethers.provider.send("evm_increaseTime", [120]);
            await ethers.provider.send("evm_mine", []);

            // Attempt to mint with incorrect price
            await expect(
                mintpad.mint(0, 1, { value: ethers.parseEther("0.05") })
            ).to.be.revertedWith("Incorrect mint price");
        });

       
    });
});
