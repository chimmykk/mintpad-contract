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


});
