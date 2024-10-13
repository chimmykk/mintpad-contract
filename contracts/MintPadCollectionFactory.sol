// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {MintpadERC721Collection} from "./MintpadERC721Collection.sol";
import {MintpadERC1155Collection} from "./MintpadERC1155Collection.sol";

/**
 * @title MintpadCollectionFactory
 * @dev This contract deploys minimal proxy instances (clones) of the MintpadERC721Collection and MintpadERC1155Collection.
 */
contract MintpadCollectionFactory is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public erc721Implementation;
    address public erc1155Implementation;

    event ERC721CollectionDeployed(address indexed collectionAddress);
    event ERC1155CollectionDeployed(address indexed collectionAddress);

    function initialize(address _erc721Implementation, address _erc1155Implementation) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        erc721Implementation = _erc721Implementation;
        erc1155Implementation = _erc1155Implementation;
    }

    /**
     * @notice Deploys a new ERC721 collection.
     * @param name_ Name of the NFT collection.
     * @param symbol_ Symbol of the NFT collection.
     * @param _maxSupply Maximum supply of tokens.
     * @param _baseTokenURI Metadata base URI after reveal.
     * @param _preRevealURI Metadata URI before reveal.
     * @param _owner Owner of the new collection.
     * @param _saleRecipient Sale proceeds recipient.
     * @param _royaltyRecipients List of royalty recipients.
     * @param _royaltyShares List of royalty share percentages.
     * @param _royaltyPercentage ERC2981 royalty percentage (in basis points).
     */
    function createERC721Collection(
        string memory name_,
        string memory symbol_,
        uint256 _maxSupply,
        string memory _baseTokenURI,
        string memory _preRevealURI,
        address _owner,
        address payable _saleRecipient,
        address payable[] memory _royaltyRecipients,
        uint16[] memory _royaltyShares,
        uint16 _royaltyPercentage
    ) external nonReentrant onlyOwner {
        address clone = Clones.clone(erc721Implementation);

        MintpadERC721Collection(clone).initialize(
            name_,
            symbol_,
            _maxSupply,
            _baseTokenURI,
            _preRevealURI,
            _owner,
            _saleRecipient,
            _royaltyRecipients,
            _royaltyShares,
            _royaltyPercentage
        );

        emit ERC721CollectionDeployed(clone);
    }

    /**
     * @notice Deploys a new ERC1155 collection.
     * @param name_ Name of the collection.
     * @param symbol_ Symbol of the collection.
     * @param _maxSupply Maximum supply of tokens.
     * @param _baseTokenURI Metadata base URI after reveal.
     * @param _preRevealURI Metadata URI before reveal.
     * @param _saleRecipient Sale proceeds recipient.
     * @param _royaltyRecipients List of royalty recipients.
     * @param _royaltyShares List of royalty share percentages.
     * @param _royaltyPercentage ERC2981 royalty percentage (in basis points).
     * @param _owner Owner of the new collection.
     */
    function createERC1155Collection(
        string memory name_,
        string memory symbol_,
        uint256 _maxSupply,
        string memory _baseTokenURI,
        string memory _preRevealURI,
        address payable _saleRecipient,
        address payable[] memory _royaltyRecipients,
        uint256[] memory _royaltyShares,
        uint96 _royaltyPercentage,
        address _owner
    ) external nonReentrant onlyOwner {
        address clone = Clones.clone(erc1155Implementation);

        MintpadERC1155Collection(clone).initialize(
            name_,
            symbol_,
            _maxSupply,
            _baseTokenURI,
            _preRevealURI,
            _saleRecipient,
            _royaltyRecipients,
            _royaltyShares,
            _royaltyPercentage,
            _owner
        );

        emit ERC1155CollectionDeployed(clone);
    }

    /**
     * @notice Updates the ERC721 implementation address.
     * @param newImplementation New implementation address for ERC721.
     */
    function updateERC721Implementation(address newImplementation) external onlyOwner {
        erc721Implementation = newImplementation;
    }

    /**
     * @notice Updates the ERC1155 implementation address.
     * @param newImplementation New implementation address for ERC1155.
     */
    function updateERC1155Implementation(address newImplementation) external onlyOwner {
        erc1155Implementation = newImplementation;
    }
}
