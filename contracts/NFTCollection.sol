// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title NFTCollection Template this will serve as the template for the mintpad ERC-721 NFT collections
 * @dev ERC721 NFT collection contract with adjustable mint price, base URI, and max supply.
 */
contract NFTCollection is ERC721Enumerable, Ownable {
    using Address for address payable;

    uint256 public mintPrice;
    uint256 public maxSupply;
    string private baseTokenURI;
    address payable public recipient;
    uint256 public developerFee;

    /**
     * @dev Initializes the contract with specified parameters.
     * @param name The name of the NFT collection.
     * @param symbol The symbol of the NFT collection.
     * @param _mintPrice The price to mint each NFT in wei.
     * @param _maxSupply The maximum number of NFTs in the collection.
     * @param _baseTokenURI The base URI for the NFT metadata.
     * @param _recipient The address to receive the funds from minted NFTs.
     * @param _developerFee The fee for the developer in wei.
     * @param owner The owner of the NFT collection.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 _mintPrice,
        uint256 _maxSupply,
        string memory _baseTokenURI,
        address payable _recipient,
        uint256 _developerFee,
        address owner
    ) ERC721(name, symbol) Ownable(owner) {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        recipient = _recipient;
        developerFee = _developerFee;
    }

    /**
     * @notice Mints a new NFT.
     * @param tokenId The ID of the token to mint.
     */
    function mint(uint256 tokenId) external payable {
        require(totalSupply() < maxSupply, "Max supply reached.");
        require(msg.value == mintPrice, "Incorrect Ether value.");

        // Transfer funds
        uint256 amountToRecipient = msg.value - developerFee;
        recipient.sendValue(amountToRecipient);
        payable(owner()).sendValue(developerFee);

        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Sets the base URI for the token metadata.
     * @param _baseTokenURI The new base URI.
     */
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @dev Returns the base URI set for the metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
