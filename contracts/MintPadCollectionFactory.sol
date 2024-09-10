// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MintpadERC721Collection.sol";
import {MintpadERC1155Collection} from "./MintpadERC1155Collection.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title MintPad Master Contract Factory
 * @dev This contract deploys individual ERC721 and ERC1155 NFT collection contracts with customizable parameters.
 *      The contract uses UUPSUpgradeable for upgradeability and charges a platform fee for each collection deployed.
 */
contract MintPadCollectionFactory is UUPSUpgradeable, OwnableUpgradeable {
    using Address for address payable;

    /// @dev Platform wallet address where fees are sent.
    address public constant platformAddress = 0x9ce7502008734772935A538Fb829741153Ca74f0;

    /// @dev Platform fee for deploying collections (0.00038 ETH).
    uint256 public constant PLATFORM_FEE = 0.00038 ether;

    event CollectionDeployed(
        address indexed collectionAddress,
        address indexed owner,
        uint256 mintPrice,
        uint256 maxSupply,
        string baseURI
    );

    event ERC1155CollectionDeployed(
        address indexed collectionAddress,
        address indexed owner,
        uint256 mintPrice,
        uint256 maxSupply,
        string baseURI
    );

    /**
     * @dev Initializes the upgradeable contract.
     *      Replaces the constructor due to UUPS pattern.
     */
    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @dev Ensures that only the contract owner can authorize upgrades.
     * @param newImplementation The address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Deploys a new ERC721 NFT collection contract with the specified parameters.
     * @param name The name of the NFT collection.
     * @param symbol The symbol of the NFT collection.
     * @param mintPrice The price to mint each NFT in wei.
     * @param maxSupply The maximum number of NFTs in the collection.
     * @param baseURI The base URI for the NFT metadata.
     * @param recipient The address to receive the funds from minted NFTs.
     * @param royaltyRecipient The address to receive royalty payments.
     * @param royaltyPercentage The royalty percentage.
     */
    function deployCollection(
        string memory name,
        string memory symbol,
        uint256 mintPrice,
        uint256 maxSupply,
        string memory baseURI,
        address payable recipient,
        address payable royaltyRecipient,
        uint256 royaltyPercentage
    ) external payable {
        require(msg.value == PLATFORM_FEE);

        // Transfer the platform fee to the platform address
        Address.sendValue(payable(platformAddress), PLATFORM_FEE);

        // Deploy a new ERC-721 collection
        MintpadERC721Collection newCollection = new MintpadERC721Collection(
            name,
            symbol,
            mintPrice,
            maxSupply,
            baseURI,
            recipient,
            royaltyRecipient,
            royaltyPercentage,
            msg.sender
        );

        // Emit the event for the new ERC-721 collection deployment
        emit CollectionDeployed(address(newCollection), msg.sender, mintPrice, maxSupply, baseURI);
    }

    /**
     * @dev Deploys a new ERC1155 NFT collection contract with the specified parameters.
     * @param collectionName The name of the NFT collection.
     * @param collectionSymbol The symbol of the NFT collection.
     * @param baseTokenURI The base URI for the NFT metadata.
     * @param mintPrice The price to mint each NFT in wei.
     * @param maxSupply The maximum number of NFTs in the collection.
     * @param recipient The address to receive the funds from minted NFTs.
     * @param royaltyRecipient The address to receive royalty payments.
     * @param royaltyPercentage The royalty percentage.
     */
    function deployERC1155Collection(
        string memory collectionName,
        string memory collectionSymbol,
        string memory baseTokenURI,
        uint256 mintPrice,
        uint256 maxSupply,
        address payable recipient,
        address payable royaltyRecipient,
        uint256 royaltyPercentage
    ) external payable {
        require(msg.value == PLATFORM_FEE, "");

        // Transfer the platform fee to the platform address
        Address.sendValue(payable(platformAddress), PLATFORM_FEE);

        // Deploy a new ERC-1155 collection
        MintpadERC1155Collection newCollection = new MintpadERC1155Collection(
            collectionName,
            collectionSymbol,
            baseTokenURI,
            mintPrice,
            maxSupply,
            recipient,
            royaltyRecipient,
            royaltyPercentage,
            msg.sender
        );

        // Emit the event for the new ERC-1155 collection deployment
        emit ERC1155CollectionDeployed(address(newCollection), msg.sender, mintPrice, maxSupply, baseTokenURI);
    }
}
