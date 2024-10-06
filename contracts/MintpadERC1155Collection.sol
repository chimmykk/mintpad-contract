// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title MintpadERC1155Collection
 * @dev Upgradeable ERC1155 NFT collection with customizable minting phases and royalty distribution.
 */
contract MintpadERC1155Collection is ERC1155Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    using Address for address payable;
    using Strings for uint256;

    // Struct to store minting phase settings
    struct PhaseSettings {
        uint256 mintPrice;
        uint256 mintLimit;
        uint256 mintStartTime;
        uint256 mintEndTime;
        bool whitelistEnabled;
    }

    // Collection metadata
    string private _collectionName;
    string private _collectionSymbol;
    uint256 public maxSupply;
    string private baseTokenURI;
    string private preRevealURI;
    bool public revealState;

    // Financial parameters
    address payable public saleRecipient;
    address payable[] public royaltyRecipients;
    uint256[] public royaltyShares;
    uint256 public royaltyPercentage;

    // Minting phases and user limits
    PhaseSettings[] public phases;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;
    mapping(uint256 => uint256) private _tokenSupply;

    /**
     * @notice Initializes the contract with collection settings
     * @param name_ Name of the NFT collection
     * @param symbol_ Symbol of the NFT collection
     * @param _maxSupply Maximum supply of the tokens
     * @param _baseTokenURI Base URI for tokens post-reveal
     * @param _preRevealURI URI for tokens before reveal
     * @param _saleRecipient Address to receive primary sale revenue
     * @param _royaltyRecipients List of royalty recipient addresses
     * @param _royaltyShares Royalty shares corresponding to each recipient
     * @param _royaltyPercentage Total royalty percentage (out of 10000, i.e., 100%)
     * @param _owner Address of the contract owner
     */
    function initialize(
        string memory name_, 
        string memory symbol_, 
        uint256 _maxSupply,
        string memory _baseTokenURI, 
        string memory _preRevealURI, 
        address payable _saleRecipient, 
        address payable[] memory _royaltyRecipients,
        uint256[] memory _royaltyShares, 
        uint256 _royaltyPercentage, 
        address _owner
    ) public initializer {
        __ERC1155_init(_baseTokenURI);
        __Ownable_init();

        require(_royaltyRecipients.length == _royaltyShares.length, "Mismatch between royalty recipients and shares");
        require(_royaltyPercentage <= 10000, "Royalty percentage exceeds 100%");

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
     * @notice Returns the collection name
     */
    function name() public view returns (string memory) {
        return _collectionName;
    }

    /**
     * @notice Returns the collection symbol
     */
    function symbol() public view returns (string memory) {
        return _collectionSymbol;
    }

    /// @dev Ensures only the owner can authorize contract upgrades.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Reveals the collection by setting the actual base URI
     * @param newBaseTokenURI The new base URI to use for the revealed collection
     */
    function revealCollection(string memory newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
        revealState = true;
    }

    /**
     * @notice Adds a new minting phase with optional whitelist
     * @param price Price per token during this phase
     * @param limit Maximum number of tokens a user can mint in this phase
     * @param startTime Start time of the phase (UNIX timestamp)
     * @param endTime End time of the phase (UNIX timestamp)
     * @param whitelistEnabled Whether whitelist is required for this phase
     */
    function addMintPhase(
        uint256 price, 
        uint256 limit, 
        uint256 startTime, 
        uint256 endTime, 
        bool whitelistEnabled
    ) external onlyOwner {
        require(startTime < endTime, "Invalid time range");

        phases.push(PhaseSettings({
            mintPrice: price,
            mintLimit: limit,
            mintStartTime: startTime,
            mintEndTime: endTime,
            whitelistEnabled: whitelistEnabled
        }));
    }

    /**
     * @notice Mints tokens during a specific phase
     * @param phaseIndex Index of the minting phase to mint from
     * @param tokenId Token ID to mint
     * @param amount Number of tokens to mint
     */
    function mint(uint256 phaseIndex, uint256 tokenId, uint256 amount) external payable {
        PhaseSettings memory phase = phases[phaseIndex];
        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime, "Minting phase inactive");
        require(_tokenSupply[tokenId] + amount <= maxSupply, "Max supply reached");
        require(msg.value == phase.mintPrice * amount, "Incorrect mint price");

        if (phase.whitelistEnabled) {
            require(whitelist[msg.sender], "Not whitelisted");
            require(whitelistMinted[msg.sender] + amount <= phase.mintLimit, "Whitelist mint limit exceeded");
            unchecked { whitelistMinted[msg.sender] += amount; }
        } else {
            require(publicMinted[msg.sender] + amount <= phase.mintLimit, "Public mint limit exceeded");
            unchecked { publicMinted[msg.sender] += amount; }
        }

        _mint(msg.sender, tokenId, amount, "");
        _tokenSupply[tokenId] += amount;

        // Distribute funds and royalties
        uint256 royaltyAmount = (msg.value * royaltyPercentage) / 10000;
        distributeRoyalties(royaltyAmount);
        saleRecipient.sendValue(msg.value - royaltyAmount);
    }

    /**
     * @notice Distributes royalties to recipients
     * @param totalAmount Total amount to distribute
     */
    function distributeRoyalties(uint256 totalAmount) internal {
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            royaltyRecipients[i].sendValue((totalAmount * royaltyShares[i]) / 10000);
        }
    }

    /**
     * @notice Manages the whitelist status for users
     * @param users List of addresses to update
     * @param status True to add to whitelist, false to remove
     */
    function manageWhitelist(address[] calldata users, bool status) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = status;
        }
    }

    /**
     * @notice Returns the token URI, using the pre-reveal URI if the collection is not revealed
     * @param tokenId The ID of the token to query
     * @return The token URI string
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_tokenSupply[tokenId] > 0, "Token does not exist");

        if (!revealState) {
            return preRevealURI;
        }

        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }

    /**
     * @notice Retrieves details of a specific minting phase
     * @param phaseIndex The index of the minting phase
     * @return mintPrice The price per token in this phase
     * @return mintLimit The maximum number of tokens a user can mint in this phase
     * @return mintStartTime The start time of the phase (UNIX timestamp)
     * @return mintEndTime The end time of the phase (UNIX timestamp)
     * @return whitelistEnabled Whether whitelist is required for this phase
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
        return (phase.mintPrice, phase.mintLimit, phase.mintStartTime, phase.mintEndTime, phase.whitelistEnabled);
    }

    /**
     * @notice Returns the total number of minting phases
     * @return The total number of phases in the contract
     */
    function getTotalPhases() external view returns (uint256) {
        return phases.length;
    }
}
