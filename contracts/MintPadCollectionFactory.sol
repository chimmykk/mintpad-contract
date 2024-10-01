// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./MintpadERC721Collection.sol";
import "./MintpadERC1155Collection.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
contract MintpadCollectionFactory is UUPSUpgradeable, OwnableUpgradeable {
    using Address for address payable;
    address public constant PLATFORM_ADDRESS = 0xbEc50cA74830c67b55CbEaf79feD8517E9d9b3B2;
    uint256 public platformFee;
    uint256 public constant MAX_ROYALTY_PERCENTAGE = 10000;
    event ERC721CollectionDeployed(
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

    /// @notice Constructor to set the initial platform fee and ownership
    constructor() {
        require(msg.sender == PLATFORM_ADDRESS, "");
        platformFee = 0.00038 ether;
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Deploys an ERC721 Collection
    function deployERC721Collection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory baseURI,
        string memory preRevealURI,
        address payable[] memory salesRecipients,
        uint256[] memory salesShares,
        address payable[] memory royaltyRecipients,
        uint256[] memory royaltyShares,
        uint256 royaltyPercentage
    ) external payable {
        require(salesRecipients.length == salesShares.length, "");
        require(royaltyRecipients.length == royaltyShares.length, "");
        MintpadERC721Collection newCollection = new MintpadERC721Collection(
            name,
            symbol,
            maxSupply,
            baseURI,
            preRevealURI,
            salesRecipients,
            salesShares,
            royaltyRecipients,
            royaltyShares,
            royaltyPercentage,
            msg.sender
        );

        emit ERC721CollectionDeployed(address(newCollection), msg.sender, maxSupply, baseURI);
    }

    /// @notice Deploys an ERC1155 Collection
    function deployERC1155Collection(
        string memory collectionName,
        string memory collectionSymbol,
        string memory baseTokenURI,
        string memory preRevealURI,
        uint256 maxSupply,
        address payable[] memory salesRecipients,
        uint256[] memory salesShares,
        address payable[] memory royaltyRecipients,
        uint256[] memory royaltyShares,
        uint256 royaltyPercentage
    ) external payable {
        require(salesRecipients.length == salesShares.length);
        require(royaltyRecipients.length == royaltyShares.length);

        MintpadERC1155Collection newCollection = new MintpadERC1155Collection(
            collectionName,
            collectionSymbol,
            maxSupply,
            baseTokenURI,
            preRevealURI,
            salesRecipients,
            salesShares,
            royaltyRecipients,
            royaltyShares,
            royaltyPercentage,
            msg.sender
        );

        emit ERC1155CollectionDeployed(address(newCollection), msg.sender, maxSupply, baseTokenURI);
    }

    /// @notice Allows the platform to update the platform fee
    function updatePlatformFee(uint256 newFee) external {
        require(msg.sender == PLATFORM_ADDRESS, "");
        platformFee = newFee;
        emit PlatformFeeUpdated(newFee);
    }

    receive() external payable {}
}
