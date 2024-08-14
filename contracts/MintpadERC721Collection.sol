// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Mintpad ERC-721 Template
 * @dev ERC721 NFT collection contract with adjustable mint price, base URI, max supply, and royalties.
 */
contract MintpadERC721Collection is ERC721Enumerable, Ownable {
    using Address for address payable;

    uint256 public mintPrice;
    uint256 public maxSupply;
    string private baseTokenURI;
    address payable public recipient;

    // Mint phase
    uint256 public mintStartTime;
    uint256 public mintEndTime;

    // Royalties
    uint256 public royaltyPercentage;
    address payable public royaltyRecipient;

    /**
     * @dev Initializes the contract with specified parameters.
     * @param name The name of the NFT collection.
     * @param symbol The symbol of the NFT collection.
     * @param _mintPrice The price to mint each NFT in wei.
     * @param _maxSupply The maximum number of NFTs in the collection.
     * @param _baseTokenURI The base URI for the NFT metadata.
     * @param _recipient The address to receive the funds from minted NFTs.
     * @param _royaltyRecipient The address to receive royalty payments.
     * @param _royaltyPercentage The royalty percentage (e.g., 500 for 5%).
     * @param owner The owner of the NFT collection.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 _mintPrice,
        uint256 _maxSupply,
        string memory _baseTokenURI,
        address payable _recipient,
        address payable _royaltyRecipient,
        uint256 _royaltyPercentage,
        address owner
    ) ERC721(name, symbol) Ownable(owner) {
        require(_royaltyPercentage <= 10000, "Royalty percentage too high");

        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        recipient = _recipient;
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    /**
     * @notice Mints a new NFT.
     * @param tokenId The ID of the token to mint.
     */
    function mint(uint256 tokenId) external payable {
        require(totalSupply() < maxSupply, "Max supply reached.");
        require(msg.value == mintPrice, "Incorrect Ether value.");
        require(block.timestamp >= mintStartTime && block.timestamp <= mintEndTime, "Minting not allowed at this time.");

        // Transfer funds
        recipient.sendValue(msg.value);

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
     * @notice Sets the mint phase (start and end time).
     * @param _mintStartTime The start time of the mint phase.
     * @param _mintEndTime The end time of the mint phase.
     */
    function setMintPhase(uint256 _mintStartTime, uint256 _mintEndTime) external onlyOwner {
        mintStartTime = _mintStartTime;
        mintEndTime = _mintEndTime;
    }

    /**
     * @notice Sets the royalty percentage and recipient.
     * @param _royaltyRecipient The address to receive royalty payments.
     * @param _royaltyPercentage The royalty percentage 
     */
    function setRoyalties(address payable _royaltyRecipient, uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage <= 10000, "Royalty percentage too high");
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    /**
     * @dev Returns the base URI set for the metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
