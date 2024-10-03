// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title MintpadERC1155Collection
 * @dev @This contract deploys individual ERC1155 NFT collection contracts with customizable parameters.
 */
contract MintpadERC1155Collection is ERC1155Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    using Address for address payable;
    using Strings for uint256; 

    // Struct to store the settings of each minting phase
    struct PhaseSettings {
        uint256 mintPrice;        // Price per token in the phase
        uint256 mintLimit;        // Maximum number of tokens that can be minted per address in the phase
        uint256 mintStartTime;    // Phase start time
        uint256 mintEndTime;      // Phase end time
        bool whitelistEnabled;    // Whether the phase requires whitelist validation
    }

    string private _collectionName; // Collection name
    string private _collectionSymbol; // Collection symbol
    uint256 public maxSupply; // Maximum supply of the token
    string private baseTokenURI; // Base URI for tokens post-reveal
    string private preRevealURI; // URI shown before the collection is revealed
    bool public revealState; // Tracks if the collection has been revealed
    address payable public saleRecipient; // Address that receives the sale proceeds
    address payable[] public royaltyRecipients; // Recipients for royalty payments
    uint256[] public royaltyShares; // Royalty share percentages for each recipient
    uint256 public royaltyPercentage; // Percentage of royalties taken from each sale

    // Store mint phases
    PhaseSettings[] public phases;
    // Whitelist mappings
    mapping(address => bool) public whitelist; // Tracks addresses eligible for whitelist minting
    mapping(address => uint256) public whitelistMinted; // Tracks tokens minted by whitelisted addresses
    mapping(address => uint256) public publicMinted; // Tracks tokens minted by non-whitelisted addresses
    mapping(uint256 => uint256) private _tokenSupply; // Tracks the supply of each token ID minted

    /**
     * @dev Initializes the contract with basic collection details, royalties, and sale recipient.
     * @param name_ The name of the collection.
     * @param symbol_ The symbol of the collection.
     * @param _maxSupply Maximum number of tokens that can be minted in this collection.
     * @param _baseTokenURI Base URI for token metadata post-reveal.
     * @param _preRevealURI URI for tokens before the collection is revealed.
     * @param _saleRecipient Address to receive the proceeds from token sales.
     * @param _royaltyRecipients List of royalty recipient addresses.
     * @param _royaltyShares List of corresponding royalty share percentages for each recipient.
     * @param _royaltyPercentage Total royalty percentage applied on sales.
     * @param _owner Address to set as the owner of the contract.
     */
    function initialize(
        string memory name_, string memory symbol_, uint256 _maxSupply,
        string memory _baseTokenURI, string memory _preRevealURI, 
        address payable _saleRecipient, address payable[] memory _royaltyRecipients,
        uint256[] memory _royaltyShares, uint256 _royaltyPercentage, address _owner
    ) initializer public {
        __ERC1155_init(_baseTokenURI);
        __Ownable_init();
        _collectionName = name_;
        _collectionSymbol = symbol_;
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        preRevealURI = _preRevealURI;
        saleRecipient = _saleRecipient;
        royaltyRecipients = _royaltyRecipients;
        royaltyShares = _royaltyShares;
        royaltyPercentage = _royaltyPercentage;
        revealState = false; 
        transferOwnership(_owner);
    }

    /**
     * @dev Authorizes contract upgrades.
     * Can only be called by the contract owner.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Allows the owner to reveal the collection by setting the actual base URI.
     * @param newBaseTokenURI The new base URI for the collection post-reveal.
     */
    function revealCollection(string memory newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
        revealState = true;
    }

    /**
     * @notice Adds a new mint phase.
     * @param price Price per token during the phase.
     * @param limit Maximum number of tokens a user can mint during the phase.
     * @param startTime Start time of the phase.
     * @param endTime End time of the phase.
     * @param whitelistEnabled Whether the phase requires whitelist validation.
     */
    function addMintPhase(
        uint256 price, uint256 limit, uint256 startTime, uint256 endTime, bool whitelistEnabled
    ) external onlyOwner {
        require(startTime < endTime, "Invalid time range");
        phases.push(PhaseSettings(price, limit, startTime, endTime, whitelistEnabled));
    }

    /**
     * @notice Mint a specific amount of tokens during a given phase.
     * @param phaseIndex The index of the minting phase.
     * @param tokenId The token ID to mint.
     * @param amount The amount of tokens to mint.
     */
    function mint(uint256 phaseIndex, uint256 tokenId, uint256 amount) external payable {
        PhaseSettings memory phase = phases[phaseIndex];
        require(
            block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime, 
            "Minting phase inactive"
        );
        require(_tokenSupply[tokenId] + amount <= maxSupply, "Max supply reached");
        require(msg.value == phase.mintPrice * amount, "Incorrect mint price");

        // Whitelist validation
        if (phase.whitelistEnabled) {
            require(whitelist[msg.sender], "Not whitelisted");
            require(whitelistMinted[msg.sender] + amount <= phase.mintLimit, "Whitelist mint limit exceeded");
            unchecked { whitelistMinted[msg.sender] += amount; }
        } else {
            // Public mint logic (if whitelist is not enabled)
            require(publicMinted[msg.sender] + amount <= phase.mintLimit, "Public mint limit exceeded");
            unchecked { publicMinted[msg.sender] += amount; }
        }

        _mint(msg.sender, tokenId, amount, "");
        _tokenSupply[tokenId] += amount;

        uint256 royaltyAmount = (msg.value * royaltyPercentage) / 10000;
        distributeRoyalties(royaltyAmount);
        saleRecipient.sendValue(msg.value - royaltyAmount);
    }

    /**
     * @notice Distributes royalties to the royalty recipients.
     * @param totalAmount Total royalty amount to distribute.
     */
    function distributeRoyalties(uint256 totalAmount) internal {
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            royaltyRecipients[i].sendValue((totalAmount * royaltyShares[i]) / 10000);
        }
    }

    /**
     * @notice Manages the whitelist by adding or removing addresses.
     * @param users List of addresses to modify.
     * @param status Boolean flag to add or remove addresses from the whitelist.
     */
    function manageWhitelist(address[] calldata users, bool status) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = status;
        }
    }

    /**
     * @notice Returns the token URI, using the pre-reveal URI if not revealed.
     * @param tokenId The ID of the token.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_tokenSupply[tokenId] > 0, "Token does not exist");

        if (!revealState) {
            return preRevealURI;
        }

        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json")); 
    }

    /**
     * @notice Retrieves details of a specific mint phase.
     * @param phaseIndex The index of the minting phase.
     * @return mintPrice Price per token in this phase.
     * @return mintLimit Maximum number of tokens a user can mint during this phase.
     * @return mintStartTime Start time of the minting phase.
     * @return mintEndTime End time of the minting phase.
     * @return whitelistEnabled Whether whitelist is enabled for this phase.
     */
    function getPhase(uint256 phaseIndex) external view returns (
        uint256 mintPrice,
        uint256 mintLimit,
        uint256 mintStartTime,
        uint256 mintEndTime,
        bool whitelistEnabled
    ) {
        require(phaseIndex < phases.length, "Invalid phase index");
        PhaseSettings memory phase = phases[phaseIndex];
        return (
            phase.mintPrice,
            phase.mintLimit,
            phase.mintStartTime,
            phase.mintEndTime,
            phase.whitelistEnabled
        );
    }

    /**
     * @notice Returns the total number of mint phases.
     * @return The total number of phases in the contract.
     */
    function getTotalPhases() external view returns (uint256) {
        return phases.length;
    }
}