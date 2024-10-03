const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MintpadERC1155Collection", function () {
    let MintpadERC1155Collection;
    let mintpad;
    let owner, addr1, addr2, addr3;

    const maxSupply = 100;
    const baseTokenURI = "ipfs://testests/";
    const preRevealURI = "ipfs://testests/";
    const saleRecipient = "0x0000000000000000000000000000000000000001";
    const royaltyPercentage = 500; // 5%
    const royaltyRecipients = [ethers.Wallet.createRandom().address]; // Random address for the test
    const royaltyShares = [1000]; // 1000 out of 10000

    beforeEach(async function () {
        [owner, addr1, addr2, addr3] = await ethers.getSigners();

        MintpadERC1155Collection = await ethers.getContractFactory("MintpadERC1155Collection");
        mintpad = await MintpadERC1155Collection.deploy();
        await mintpad.initialize(
            "Test ERC1155 Token", // Collection name
            "TT1155", // Collection symbol
            maxSupply,
            baseTokenURI,
            preRevealURI,
            saleRecipient,
            royaltyRecipients,
            royaltyShares,
            royaltyPercentage,
            owner.address
        );
    });

    describe("Initialization", function () {
        it("should set the correct collection name", async function () {
            expect(await mintpad.name()).to.equal("Test ERC1155 Token");
        });

        it("should set the correct collection symbol", async function () {
            expect(await mintpad.symbol()).to.equal("TT1155");
        });

        it("should set the correct sale recipient", async function () {
            expect(await mintpad.saleRecipient()).to.equal(saleRecipient);
        });

        it("should set the correct royalty settings", async function () {
            expect(await mintpad.royaltyPercentage()).to.equal(royaltyPercentage);
            expect(await mintpad.royaltyRecipients(0)).to.equal(royaltyRecipients[0]);
        });

        it("should set the max supply correctly", async function () {
            expect(await mintpad.maxSupply()).to.equal(maxSupply);
        });
    });

    describe("Minting Phases", function () {
        it("should allow the owner to add a mint phase", async function () {
            const price = ethers.parseEther("0.1");
            const limit = 10;
            const startTime = Math.floor(Date.now() / 1000) + 60; // Starts in 1 minute
            const endTime = startTime + 3600; // Ends in 1 hour
            const whitelistEnabled = true;

            await mintpad.addMintPhase(price, limit, startTime, endTime, whitelistEnabled);
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
                mintpad.connect(addr1).addMintPhase(price, limit, startTime, endTime, whitelistEnabled)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });
    });
});
