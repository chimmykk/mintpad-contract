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
        uint256 maxSupply,
        string baseURI
    );
    event ERC1155CollectionDeployed(
        address indexed collectionAddress,
        address indexed owner,
        uint256 maxSupply,
        string baseURI
    );

    event PlatformFeeUpdated(uint16 newFee);  

    /// @notice Constructor to set the initial platform fee and ownership
    constructor() {
        require(msg.sender == PLATFORM_ADDRESS);
        platformFee = 38;  // Set platform fee to 0.00038 ether (in uint16 format for optimization)
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Deploys an ERC721 Collection without sales shares
    function deployERC721Collection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory baseURI,
        string memory preRevealURI,
        address payable saleRecipient,  // Single recipient for sales
        address payable[] memory royaltyRecipients,
        uint16[] memory royaltyShares,
        uint16 royaltyPercentage
    ) external payable {
        require(royaltyRecipients.length == royaltyShares.length);
        require(royaltyPercentage <= MAX_ROYALTY_PERCENTAGE);

        MintpadERC721Collection newCollection = new MintpadERC721Collection(
            name,
            symbol,
            maxSupply,
            baseURI,
            preRevealURI,
            saleRecipient,      
            royaltyRecipients,   
            royaltyShares,       
            royaltyPercentage,
            msg.sender   
        );

        emit ERC721CollectionDeployed(address(newCollection), msg.sender, maxSupply, baseURI);
    }

    /// @notice Deploys an ERC1155 Collection without sales shares
    function deployERC1155Collection(
        string memory collectionName,
        string memory collectionSymbol,
        string memory baseTokenURI,
        string memory preRevealURI,
        uint256 maxSupply,
        address payable saleRecipient,  
        address payable[] memory royaltyRecipients,
        uint256[] memory royaltyShares, 
        uint16 royaltyPercentage  
    ) external payable {
        require(royaltyRecipients.length == royaltyShares.length);
        require(royaltyPercentage <= MAX_ROYALTY_PERCENTAGE);

        MintpadERC1155Collection newCollection = new MintpadERC1155Collection(
            collectionName,
            collectionSymbol,
            maxSupply,
            baseTokenURI,
            preRevealURI,
            saleRecipient,      
            royaltyRecipients,   
            royaltyShares,       
            royaltyPercentage,
            msg.sender         
        );

        emit ERC1155CollectionDeployed(address(newCollection), msg.sender, maxSupply, baseTokenURI);
    }

    /// @notice Allows the platform to update the platform fee
    function updatePlatformFee(uint16 newFee) external {  // Use uint16 for platform fee
        require(msg.sender == PLATFORM_ADDRESS);
        platformFee = newFee;
        emit PlatformFeeUpdated(newFee);
    }

    receive() external payable {}
}
