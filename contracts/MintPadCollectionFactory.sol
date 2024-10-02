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
    uint16 public platformFee; 
    uint16 public constant MAX_ROYALTY_PERCENTAGE = 10000;

    event ERC721CollectionDeployed(
        address indexed collectionAddress,
        address indexed owner,
        uint256 maxSupply
    );
    event ERC1155CollectionDeployed(
        address indexed collectionAddress,
        address indexed owner,
        uint256 maxSupply
    );
    event PlatformFeeUpdated(uint16 newFee);

    constructor() {
        require(msg.sender == PLATFORM_ADDRESS);
        platformFee = 38; 
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  /// @notice Deploys an ERC721 Collection
function deployERC721Collection(
    string memory name,
    string memory symbol,
    uint256 maxSupply,
    string memory baseURI,
    address owner,
    address payable saleRecipient,
    address payable[] memory royaltyRecipients,
    uint16[] memory royaltyShares,
    uint16 royaltyPercentage
) external payable {
    MintpadERC721Collection newCollection = new MintpadERC721Collection(
        name, symbol, maxSupply, baseURI, owner,
        saleRecipient, royaltyRecipients, royaltyShares, royaltyPercentage
    );

    emit ERC721CollectionDeployed(address(newCollection), owner, maxSupply);
}
    /// @notice Deploys an ERC1155 Collection
    function deployERC1155Collection(
        string memory collectionName,
        string memory baseTokenURI,
        string memory preRevealURI,
        uint256 maxSupply,
        address payable saleRecipient,
        address payable[] memory royaltyRecipients,
        uint256[] memory royaltyShares,
        uint256 royaltyPercentage,
        address owner
    ) external payable {
        require(royaltyPercentage <= MAX_ROYALTY_PERCENTAGE);

        MintpadERC1155Collection newCollection = new MintpadERC1155Collection(
            collectionName, collectionName, maxSupply, baseTokenURI, preRevealURI, saleRecipient, 
            royaltyRecipients, royaltyShares, royaltyPercentage, owner
        );

        emit ERC1155CollectionDeployed(address(newCollection), owner, maxSupply);
    }

    /// @notice Allows platform to update the platform fee
    function updatePlatformFee(uint16 newFee) external {  
        require(msg.sender == PLATFORM_ADDRESS);
        platformFee = newFee;
        emit PlatformFeeUpdated(newFee);
    }

    receive() external payable {}
}
