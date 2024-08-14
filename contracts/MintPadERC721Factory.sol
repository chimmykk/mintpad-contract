// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MintpadERC721Collection.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title MintPad Master Contract Factory
 * @dev This contract deploys individual ERC721 NFT collection contracts with customizable parameters.
 */
contract MintPadERC721Factory is UUPSUpgradeable, OwnableUpgradeable {
    using Address for address payable;

    /// @dev Hardcoded platform wallet address
    address public constant platformAddress = 0x9ce7502008734772935A538Fb829741153Ca74f0;

    /// @dev Hardcoded platform fee  (0.00038 ETH)
    uint256 public constant PLATFORM_FEE = 0.00038 ether;

    event CollectionDeployed(address indexed collectionAddress, address indexed owner, uint256 mintPrice, uint256 maxSupply, string baseURI);

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
        require(msg.value == PLATFORM_FEE, "Incorrect platform fee.");

        // Transfer the platform fee to the hardcoded platform address
        Address.sendValue(payable(platformAddress), PLATFORM_FEE);

        // Deploy the new NFT collection contract
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

        emit CollectionDeployed(address(newCollection), msg.sender, mintPrice, maxSupply, baseURI);
    }
}
