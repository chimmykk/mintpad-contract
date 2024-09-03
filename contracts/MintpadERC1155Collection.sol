// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Mintpad ERC-1155 Template
 * @dev ERC1155 NFT collection contract with adjustable mint price, max supply, and royalties.
 */
contract MintpadERC1155Collection is ERC1155, Ownable {
    using Address for address payable;
    using Strings for uint256;

    string public collectionName;
    string public collectionSymbol;
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public currentSupply;
    string private baseTokenURI;
    address payable public recipient;

    uint256 public royaltyPercentage;
    address payable public royaltyRecipient;

    /**
     * @dev Initializes the contract with specified parameters.
     * @param _collectionName The name of the NFT collection.
     * @param _collectionSymbol The symbol of the NFT collection.
     * @param _baseTokenURI The base URI for the NFT metadata.
     * @param _mintPrice The price to mint each NFT in wei.
     * @param _maxSupply The maximum number of NFTs in the collection.
     * @param _recipient The address to receive the funds from minted NFTs.
     * @param _royaltyRecipient The address to receive royalty payments.
     * @param _royaltyPercentage The royalty percentage (e.g., 500 for 5%).
     * @param owner The owner of the NFT collection.
     */
    constructor(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _baseTokenURI,
        uint256 _mintPrice,
        uint256 _maxSupply,
        address payable _recipient,
        address payable _royaltyRecipient,
        uint256 _royaltyPercentage,
        address owner
    ) ERC1155(_baseTokenURI) Ownable(owner) {
        require(_royaltyPercentage <= 10000, "Royalty percentage too high");

        collectionName = _collectionName;
        collectionSymbol = _collectionSymbol;
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        recipient = _recipient;
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    /**
     * @notice Mints a new NFT.
     * @param id The ID of the token to mint.
     * @param amount The number of tokens to mint.
     */
    function mint(uint256 id, uint256 amount) external payable {
        require(currentSupply + amount <= maxSupply, "Max supply reached.");
        require(msg.value == mintPrice * amount, "Incorrect Ether value.");

        // Transfer funds
        recipient.sendValue(msg.value);

        _mint(msg.sender, id, amount, "");
        currentSupply += amount;
    }

    /**
     * @notice Sets the base URI for the token metadata.
     * @param _baseTokenURI The new base URI.
     */
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
        _setURI(baseTokenURI);
    }

    /**
     * @notice Sets the royalty percentage and recipient.
     * @param _royaltyRecipient The address to receive royalty payments.
     * @param _royaltyPercentage The royalty percentage.
     */
    function setRoyalties(address payable _royaltyRecipient, uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage <= 10000, "Royalty percentage too high");
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    /**
     * @dev Returns the metadata URI for a given token ID.
     * @param tokenId The ID of the token.
     * @return The metadata URI for the token.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(bytes(baseTokenURI).length > 0, "ERC1155Metadata: Base URI not set");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }
}
