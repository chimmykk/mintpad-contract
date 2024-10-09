// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title MintpadERC721Collection
 * @dev Upgradeable ERC721 collection with customizable minting phases and royalty distribution.
 *      Supports ERC2981 royalties.
 */
contract MintpadERC721Collection is 
    ERC721AUpgradeable, 
    UUPSUpgradeable, 
    OwnableUpgradeable, 
    ReentrancyGuardUpgradeable, 
    ERC2981Upgradeable 
{
    using Address for address payable;
    using Strings for uint256;

    /// @notice Maximum number of tokens that can be minted in this collection.
    uint256 public maxSupply;

    /// @notice Base URI for metadata post-reveal.
    string private baseTokenURI;

    /// @notice URI for the metadata when the collection is not revealed.
    string private preRevealURI;

    /// @notice Indicates if the collection has been revealed.
    bool public revealed;

    /// @notice Recipient for sale proceeds.
    address payable public saleRecipient;

    /// @notice Recipients for royalty payments.
    address payable[] public royaltyRecipients;

    /// @notice Shares for royalty recipients, in basis points.
    uint16[] public royaltyShares;

    /// @notice Percentage of royalties (in basis points) from each sale.
    uint96 public royaltyPercentage; // Max 10000 (for 100%)

    /// @dev Struct to define a minting phase.
    struct PhaseSettings {
        uint128 mintPrice;      // Price per token during the phase
        uint32 mintLimit;       // Per user mint limit in this phase
        uint32 mintStartTime;   // Phase start time (UNIX timestamp)
        uint32 mintEndTime;     // Phase end time (UNIX timestamp)
        bool whitelistEnabled;  // Whether whitelist is enabled
        bytes32 merkleRoot;     // Merkle root for whitelisting
    }

    /// @notice Array of minting phases.
    PhaseSettings[] public phases;

    /// @notice Tracks the number of tokens minted by an address.
    mapping(address => uint32) public minted;

    /**
     * @dev Initializes the contract with settings.
     * @param name_ Name of the NFT collection.
     * @param symbol_ Symbol for the NFT collection.
     * @param _maxSupply Maximum supply of tokens.
     * @param _baseTokenURI Metadata base URI after reveal.
     * @param _preRevealURI Metadata URI before reveal.
     * @param _owner Address of the contract owner.
     * @param _saleRecipient Address to receive sale proceeds.
     * @param _royaltyRecipients List of royalty recipients.
     * @param _royaltyShares List of royalty share percentages (in basis points).
     * @param _royaltyPercentage Royalty percentage for ERC2981 (in basis points).
     */
    function initialize(
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
    ) initializer public {
        __ERC721A_init(name_, symbol_);
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC2981_init();

        require(_royaltyRecipients.length == _royaltyShares.length, "Mismatch in royalty recipients and shares");
        require(_royaltyPercentage <= 10000, "Royalty percentage exceeds 100%");

        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        preRevealURI = _preRevealURI;
        saleRecipient = _saleRecipient;
        royaltyRecipients = _royaltyRecipients;
        royaltyShares = _royaltyShares;
        royaltyPercentage = _royaltyPercentage;
        revealed = false;

        transferOwnership(_owner);

        // Set a default royalty for the entire collection (can be changed later)
        _setDefaultRoyalty(_saleRecipient, _royaltyPercentage); 
    }

    /// @dev Authorization for contract upgrades, only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Adds a new mint phase with optional whitelist using a Merkle tree.
     * @param price Price per token during the mint phase.
     * @param limit Maximum number of tokens that can be minted per address in this phase.
     * @param startTime Start time for the mint phase (Unix timestamp).
     * @param endTime End time for the mint phase (Unix timestamp).
     * @param whitelistEnabled Boolean flag indicating if whitelist is required.
     * @param merkleRoot Merkle root for whitelist verification.
     */
    function addMintPhase(
        uint128 price,
        uint32 limit,
        uint32 startTime,
        uint32 endTime,
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
     * @notice Mint tokens during a specific phase.
     * @param phaseIndex Index of the phase from which to mint.
     * @param quantity Number of tokens to mint.
     * @param merkleProof Merkle proof for whitelist verification.
     */
    function mint(uint256 phaseIndex, uint256 quantity, bytes32[] calldata merkleProof) external payable nonReentrant {
        require(phaseIndex < phases.length, "Invalid phase index");
        PhaseSettings storage phase = phases[phaseIndex];

        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime, "Minting phase inactive");
        require(totalSupply() + quantity <= maxSupply, "Max supply reached");
        require(msg.value == phase.mintPrice * quantity, "Incorrect mint price");
        require(minted[msg.sender] + uint32(quantity) <= phase.mintLimit, "Mint limit exceeded");

        if (phase.whitelistEnabled) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, phase.merkleRoot, leaf), "Not whitelisted for this phase");
        }

        minted[msg.sender] += uint32(quantity); // Cast to uint32
        _safeMint(msg.sender, quantity);

        uint256 royaltyAmount = (msg.value * royaltyPercentage) / 10000;
        distributeRoyalties(royaltyAmount);
        saleRecipient.sendValue(msg.value - royaltyAmount);
    }

    /**
     * @dev Distributes royalties to the royalty recipients.
     * @param totalAmount Total amount to be distributed as royalties.
     */
    function distributeRoyalties(uint256 totalAmount) internal {
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            royaltyRecipients[i].sendValue((totalAmount * royaltyShares[i]) / 10000);
        }
    }

    /**
     * @notice Returns the token URI, using the pre-reveal URI if the collection is not revealed.
     * @param tokenId ID of the token.
     * @return URI string for the token's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        if (!revealed) {
            return preRevealURI;
        }

        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }

    /**
     * @notice Reveals the collection by setting the actual base URI.
     * @param newBaseTokenURI The new base URI for token metadata.
     */
    function revealCollection(string memory newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
        revealed = true;
    }

 
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
        return (
            phase.mintPrice,
            phase.mintLimit,
            phase.mintStartTime,
            phase.mintEndTime,
            phase.whitelistEnabled,
            phase.merkleRoot
        );
    }

    /**
     * @notice Returns the total number of minting phases.
     * @return Total number of minting phases.
     */
    function getTotalPhases() external view returns (uint256) {
        return phases.length;
    }

    /**
     * @notice Set royalties for a specific token as per ERC2981.
     * @param tokenId ID of the token.
     * @param recipient Recipient of the royalty.
     * @param feeNumerator Royalty amount in basis points.
     */
    function setTokenRoyalty(uint256 tokenId, address recipient, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, recipient, feeNumerator);
    }

    /**
     * @notice Set default royalties for all tokens as per ERC2981.
     * @param recipient Recipient of the royalty.
     * @param feeNumerator Royalty amount in basis points.
     */
    function setDefaultRoyalty(address recipient, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(recipient, feeNumerator);
    }

    /// @dev Overrides to support ERC2981.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
