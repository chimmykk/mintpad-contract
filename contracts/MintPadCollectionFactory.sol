// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./MintpadERC721Collection.sol";
import "./MintpadERC1155Collection.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MintpadCollectionFactory is UUPSUpgradeable, OwnableUpgradeable {
    using Address for address payable;

    address public constant PLATFORM_ADDRESS = 0xbEc50cA74830c67b55CbEaf79feD8517E9d9b3B2;
    uint16 public constant MAX_ROYALTY_PERCENTAGE = 10000;

    address public erc721Implementation;
    address public erc1155Implementation;

    uint256 public platformFee;  // Changed to a state variable

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
    event PlatformFeeUpdated(uint256 newFee);

    /// @notice Initializes the factory and sets initial values
    function initialize(address _erc721Implementation, address _erc1155Implementation) external initializer {
        require(msg.sender == PLATFORM_ADDRESS, "Caller is not the platform");
        erc721Implementation = _erc721Implementation;
        erc1155Implementation = _erc1155Implementation;
        platformFee = 0.00038 ether;  // Set initial platform fee
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Deploys an upgradeable ERC721 Collection with a fixed platform fee
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
        require(royaltyPercentage <= MAX_ROYALTY_PERCENTAGE, "Royalty percentage exceeds maximum");
        require(msg.value >= platformFee, "Insufficient funds for platform fee");
        payable(PLATFORM_ADDRESS).sendValue(platformFee);

        // Deploy the ERC721 Collection
        ERC1967Proxy proxy = new ERC1967Proxy(
            erc721Implementation,
            abi.encodeWithSelector(
                MintpadERC721Collection.initialize.selector,
                name, symbol, maxSupply, baseURI, owner, saleRecipient, royaltyRecipients, royaltyShares, royaltyPercentage
            )
        );

        // Emit event
        emit ERC721CollectionDeployed(address(proxy), owner, maxSupply);
    }

    /// @notice Deploys an upgradeable ERC1155 Collection 
    function deployERC1155Collection(
        string memory collectionName,
        string memory baseTokenURI,
        uint256 maxSupply,
        address payable saleRecipient,
        address payable[] memory royaltyRecipients,
        uint256[] memory royaltyShares,
        uint256 royaltyPercentage,
        address owner
    ) external payable {
        require(royaltyPercentage <= MAX_ROYALTY_PERCENTAGE, "Royalty percentage exceeds maximum");
        require(msg.value >= platformFee, "Insufficient funds for platform fee");

        payable(PLATFORM_ADDRESS).sendValue(platformFee);

        ERC1967Proxy proxy = new ERC1967Proxy(
            erc1155Implementation,
            abi.encodeWithSelector(
                MintpadERC1155Collection.initialize.selector,
                collectionName, collectionName, maxSupply, baseTokenURI, saleRecipient, royaltyRecipients, royaltyShares, royaltyPercentage, owner
            )
        );

   
        emit ERC1155CollectionDeployed(address(proxy), owner, maxSupply);
    }

    /// @notice Allows the platform to update the platform fee
    function updatePlatformFee(uint256 newFee) external {
        require(msg.sender == PLATFORM_ADDRESS, "Caller is not the platform");
        platformFee = newFee;
        emit PlatformFeeUpdated(newFee);
    }

    receive() external payable {}
}
