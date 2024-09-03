// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Open Edition + Burn Contract
 * @dev ERC1155 contract that allows unlimited minting during an open edition period and burning of tokens for rewards.
 */
contract MintpadERC1155OpenEdition is ERC1155, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint256 public mintPrice;
    uint256 public currentSupply;
    string private baseTokenURI;
    address payable public recipient;
    uint256 public openEditionEndTime;

    // Collection details
    string public collectionName;
    string public collectionSymbol;

    // Mapping to track burned tokens
    mapping(address => uint256) public burnedTokens;

    event Minted(address indexed minter, uint256 amount);
    event Burned(address indexed burner, uint256 amount, uint256 reward);

    /**
     * @dev Initializes the contract with specified parameters.
     * @param _collectionName The name of the NFT collection.
     * @param _collectionSymbol The symbol of the NFT collection.
     * @param _baseTokenURI The base URI for the NFT metadata.
     * @param _mintPrice The price to mint each NFT in wei.
     * @param _recipient The address to receive the funds from minted NFTs.
     * @param _openEditionDuration The duration for which the open edition is active (in seconds).
     * @param owner The owner of the contract.
     */
    constructor(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _baseTokenURI,
        uint256 _mintPrice,
        address payable _recipient,
        uint256 _openEditionDuration,
        address owner
    ) ERC1155(_baseTokenURI) Ownable(owner) {
        collectionName = _collectionName;
        collectionSymbol = _collectionSymbol;
        mintPrice = _mintPrice;
        baseTokenURI = _baseTokenURI;
        recipient = _recipient;
        openEditionEndTime = block.timestamp + _openEditionDuration;
    }

    /**
     * @notice Mints new tokens during the open edition period.
     * @param amount The number of tokens to mint.
     */
    function mint(uint256 amount) external payable {
        require(block.timestamp <= openEditionEndTime, "Open edition has ended.");
        require(msg.value == mintPrice * amount, "Incorrect Ether value.");

        // Transfer funds
        recipient.sendValue(msg.value);

        _mint(msg.sender, 1, amount, ""); // Minting the same token ID (1) for simplicity
        currentSupply += amount;

        emit Minted(msg.sender, amount);
    }

    /**
     * @notice Burns the specified number of tokens for a reward.
     * @param amount The number of tokens to burn.
     */
    function burn(uint256 amount) external {
        require(balanceOf(msg.sender, 1) >= amount, "Insufficient balance to burn.");

        _burn(msg.sender, 1, amount);
        burnedTokens[msg.sender] += amount;

        // Define reward logic here. This can be anything, like sending a different token, etc.
        uint256 reward = calculateReward(amount);

        emit Burned(msg.sender, amount, reward);
    }

    /**
     * @notice Calculates the reward for burning tokens.
     * @param amount The amount of tokens burned.
     * @return The reward amount.
     */
    function calculateReward(uint256 amount) internal pure returns (uint256) {
        // Example reward logic: 1 token burned = 1 ether reward (this is just an example and needs actual logic)
        return amount * 1 ether;
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
     * @dev Returns the metadata URI for a given token ID.
     * @param tokenId The ID of the token.
     * @return The metadata URI for the token.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(bytes(baseTokenURI).length > 0, "ERC1155Metadata: Base URI not set");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }
}
