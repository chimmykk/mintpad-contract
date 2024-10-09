// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

/**
 * @title MintpadERC1155Collection
 * @dev Upgradeable ERC1155 NFT collection with customizable minting phases and royalty distribution.
 */
contract MintpadERC1155Collection is ERC1155Upgradeable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC2981Upgradeable {
    using Address for address payable;
    using Strings for uint256;

    // Struct to store minting phase settings
    struct PhaseSettings {
        uint256 mintPrice;
        uint256 mintLimit;
        uint256 mintStartTime;
        uint256 mintEndTime;
        bool whitelistEnabled;
        bytes32 merkleRoot; // Merkle root for whitelisting
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
    uint96 public royaltyPercentage; // Change to uint96

    // Minting phases and user limits
    PhaseSettings[] public phases;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;
    mapping(uint256 => uint256) private _tokenSupply;

    /**
     * @notice Initializes the contract with collection settings
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
        uint96 _royaltyPercentage, // Change to uint96
        address _owner
    ) public initializer {
        __ERC1155_init(_baseTokenURI);
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC2981_init();

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

        // Set default royalty for the collection
        _setDefaultRoyalty(_saleRecipient, _royaltyPercentage);
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
     */
    function revealCollection(string memory newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
        revealState = true;
    }

    /**
     * @notice Adds a new minting phase with optional whitelist using a Merkle tree
     */
    function addMintPhase(
        uint256 price, 
        uint256 limit, 
        uint256 startTime, 
        uint256 endTime, 
        bool whitelistEnabled,
        bytes32 merkleRoot
    ) external onlyOwner {
        require(startTime < endTime, "Invalid time range");

        phases.push(PhaseSettings({
            mintPrice: price,
            mintLimit: limit,
            mintStartTime: startTime,
            mintEndTime: endTime,
            whitelistEnabled: whitelistEnabled,
            merkleRoot: merkleRoot
        }));
    }

    /**
     * @notice Mints tokens during a specific phase
     */
    function mint(uint256 phaseIndex, uint256 tokenId, uint256 amount, bytes32[] calldata merkleProof) external payable nonReentrant {
        PhaseSettings memory phase = phases[phaseIndex];
        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime, "Minting phase inactive");
        require(_tokenSupply[tokenId] + amount <= maxSupply, "Max supply reached");
        require(msg.value == phase.mintPrice * amount, "Incorrect mint price");

        if (phase.whitelistEnabled) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, phase.merkleRoot, leaf), "Not whitelisted");
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
     */
    function distributeRoyalties(uint256 totalAmount) internal {
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            royaltyRecipients[i].sendValue((totalAmount * royaltyShares[i]) / 10000);
        }
    }

    /**
     * @notice Returns the token URI, using the pre-reveal URI if the collection is not revealed
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
     */
    function getPhase(uint256 phaseIndex) external view returns (
        uint256 mintPrice,
        uint256 mintLimit,
        uint256 mintStartTime,
        uint256 mintEndTime,
        bool whitelistEnabled,
        bytes32 merkleRoot
    ) {
        require(phaseIndex < phases.length, "Invalid phase index");
        PhaseSettings memory phase = phases[phaseIndex];
        return (phase.mintPrice, phase.mintLimit, phase.mintStartTime, phase.mintEndTime, phase.whitelistEnabled, phase.merkleRoot);
    }

    /**
     * @notice Returns the total number of minting phases
     */
    function getTotalPhases() external view returns (uint256) {
        return phases.length;
    }

    /**
     * @dev Overrides to support ERC2981 and ERC1155
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
