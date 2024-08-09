// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./NFTCollection.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title MintPad Master Contract Factory
 * @dev This contract deploys individual ERC721 NFT collection contracts with customizable parameters.
 */
contract MasterNFTFactory {
    using Address for address payable;

    /// @dev Platform wallet address
    address public platformAddress = 0x4ec431790805909b0D3Dcf5C8dA25FCBF46E93F8;

    /// @dev Platform fee in wei (0.001 ETH)
    uint256 public constant PLATFORM_FEE = 0.001 ether;

    event CollectionDeployed(address indexed collectionAddress, address indexed owner, uint256 mintPrice, uint256 maxSupply, string baseURI);

    /**
     * @dev Deploys a new ERC721 NFT collection contract with the specified parameters.
     * @param name The name of the NFT collection.
     * @param symbol The symbol of the NFT collection.
     * @param mintPrice The price to mint each NFT in wei.
     * @param maxSupply The maximum number of NFTs in the collection.
     * @param baseURI The base URI for the NFT metadata.
     * @param recipient The address to receive the funds from minted NFTs.
     * @param developerFee The fee for the developer in wei.
     */
    function deployCollection(
        string memory name,
        string memory symbol,
        uint256 mintPrice,
        uint256 maxSupply,
        string memory baseURI,
        address payable recipient,
        uint256 developerFee
    ) external payable {
        require(msg.value == PLATFORM_FEE, "Incorrect platform fee.");

        // Transfer the platform fee to the platform address
        payable(platformAddress).sendValue(PLATFORM_FEE);

        // Deploy the new NFT collection contract
        NFTCollection newCollection = new NFTCollection(
            name,
            symbol,
            mintPrice,
            maxSupply,
            baseURI,
            recipient,
            developerFee,
            msg.sender
        );

        emit CollectionDeployed(address(newCollection), msg.sender, mintPrice, maxSupply, baseURI);
    }
}
