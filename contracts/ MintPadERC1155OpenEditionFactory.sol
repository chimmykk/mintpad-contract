// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MintpadERC1155OpenEdition} from "./MintpadERC1155OpenEdition.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title MintPad ERC1155 Open Edition Master Contract Factory
 * @dev This contract deploys ERC1155 Open Edition NFT collection contracts with customizable parameters.
 */
contract MintPadERC1155OpenEditionFactory is UUPSUpgradeable, OwnableUpgradeable {
    using Address for address payable;

    /// @dev Hardcoded platform wallet address
    address public constant platformAddress = 0x9ce7502008734772935A538Fb829741153Ca74f0;

    /// @dev Hardcoded platform fee (0.00038 ETH)
    uint256 public constant PLATFORM_FEE = 0.00038 ether;

    event ERC1155OpenEditionDeployed(address indexed collectionAddress, address indexed owner, string collectionName, string collectionSymbol, uint256 mintPrice, string baseURI, uint256 openEditionDuration);

    /**
     * @dev Ensures that only the contract owner can authorize upgrades.
     * @param newImplementation The address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Deploys a new ERC1155 Open Edition + Burn contract with the specified parameters.
     * @param collectionName The name of the NFT collection.
     * @param collectionSymbol The symbol of the NFT collection.
     * @param baseTokenURI The base URI for the NFT metadata.
     * @param mintPrice The price to mint each NFT in wei.
     * @param recipient The address to receive the funds from minted NFTs.
     * @param openEditionDuration The duration for which the open edition is active (in seconds).
     */
    function deployERC1155OpenEdition(
        string memory collectionName,
        string memory collectionSymbol,
        string memory baseTokenURI,
        uint256 mintPrice,
        address payable recipient,
        uint256 openEditionDuration
    ) external payable {
        require(msg.value == PLATFORM_FEE, "Incorrect platform fee.");
        Address.sendValue(payable(platformAddress), PLATFORM_FEE);
        MintpadERC1155OpenEdition newCollection = new MintpadERC1155OpenEdition(
            collectionName,
            collectionSymbol,
            baseTokenURI,
            mintPrice,
            recipient,
            openEditionDuration,
            msg.sender
        );

        emit ERC1155OpenEditionDeployed(address(newCollection), msg.sender, collectionName, collectionSymbol, mintPrice, baseTokenURI, openEditionDuration);
    }
}
