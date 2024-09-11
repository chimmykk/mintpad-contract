// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MintpadERC721Collection.sol";
import {MintpadERC1155Collection} from "./MintpadERC1155Collection.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MintPadCollectionFactory is UUPSUpgradeable, OwnableUpgradeable {
    using Address for address payable;

    address public constant PLATFORM_ADDRESS = 0xbEc50cA74830c67b55CbEaf79feD8517E9d9b3B2;
    uint256 public platformFee;
    uint256 public constant MAX_ROYALTY_PERCENTAGE = 10000;

    event CollectionDeployed(
        address indexed collectionAddress,
        address indexed owner,
        uint256 maxSupply,
        string baseURI
    );

    event ERC1155CollectionDeployed(
        address indexed collectionAddress,
        address indexed owner,
        uint256 maxSupply,
        string baseURI
    );

    event PlatformFeeUpdated(uint256 newFee);

    function initialize() external initializer {
        require(msg.sender == PLATFORM_ADDRESS);
        __Ownable_init();
        platformFee = 0.00038 ether;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function deployCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory baseURI,
        address payable recipient,
        address payable royaltyRecipient,
        uint256 royaltyPercentage
    ) external payable {
        require(msg.value == platformFee);
        require(royaltyPercentage <= MAX_ROYALTY_PERCENTAGE);

        // Transfer the platform fee to the platform address
        Address.sendValue(payable(PLATFORM_ADDRESS), platformFee);

        // Deploy a new ERC-721 collection
        MintpadERC721Collection newCollection = new MintpadERC721Collection(
            name,
            symbol,
            maxSupply,
            baseURI,
            recipient,
            royaltyRecipient,
            royaltyPercentage,
            msg.sender
        );

        emit CollectionDeployed(address(newCollection), msg.sender, maxSupply, baseURI);
    }

    function deployERC1155Collection(
        string memory collectionName,
        string memory collectionSymbol,
        string memory baseTokenURI,
        uint256 maxSupply,
        address payable recipient,
        address payable royaltyRecipient,
        uint256 royaltyPercentage
    ) external payable {
        require(msg.value == platformFee);
        require(royaltyPercentage <= MAX_ROYALTY_PERCENTAGE);

        Address.sendValue(payable(PLATFORM_ADDRESS), platformFee);

        MintpadERC1155Collection newCollection = new MintpadERC1155Collection(
            collectionName,
            collectionSymbol,
            baseTokenURI,
            maxSupply,
            recipient,
            royaltyRecipient,
            royaltyPercentage,
            msg.sender
        );

        emit ERC1155CollectionDeployed(address(newCollection), msg.sender, maxSupply, baseTokenURI);
    }

    function updatePlatformFee(uint256 newFee) external {
        require(msg.sender == PLATFORM_ADDRESS);
        platformFee = newFee;
        emit PlatformFeeUpdated(newFee);
    }

    receive() external payable {}
}
