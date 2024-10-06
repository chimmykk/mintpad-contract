// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title MintpadERC721Collection
 * @dev Upgradeable ERC721 collection with customizable minting phases and royalty distribution.
 */
contract MintpadERC721Collection is ERC721Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    using Address for address payable;
    using Strings for uint256;

    uint256 public maxSupply;
    uint256 private _totalMinted;
    string private baseTokenURI;
    string private preRevealURI;
    bool public revealed;
    string private _collectionName;
    string private _collectionSymbol;

    address payable public saleRecipient;
    address payable[] public royaltyRecipients;
    uint16[] public royaltyShares;
    uint16 public royaltyPercentage; // Max 10000 (for 100%)

    struct PhaseSettings {
        uint128 mintPrice;      // Price per token during the phase
        uint32 mintLimit;       // Per user mint limit in this phase
        uint32 mintStartTime;   // Phase start time (UNIX timestamp)
        uint32 mintEndTime;     // Phase end time (UNIX timestamp)
        bool whitelistEnabled;  // Whether this phase requires whitelist
    }

    PhaseSettings[] public phases; // Array of minting phases
    mapping(uint256 => mapping(address => bool)) public phaseWhitelist; // phaseIndex => user => status
    mapping(address => uint32) public minted; // Track tokens minted per user

    /**
     * @notice Initializes the contract with the provided settings.
     * @param name_ Name of the NFT collection
     * @param symbol_ Symbol of the NFT collection
     * @param _maxSupply Maximum number of NFTs that can be minted
     * @param _baseTokenURI Base URI for token metadata after the reveal
     * @param _preRevealURI URI to use before the collection is revealed
     * @param _owner Address of the contract owner
     * @param _saleRecipient Address that will receive the primary sale revenue
     * @param _royaltyRecipients Array of addresses that will receive royalties
     * @param _royaltyShares Percentage shares for each royalty recipient
     * @param _royaltyPercentage Total royalty percentage (out of 10000, i.e. 100%)
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
        __ERC721_init(name_, symbol_);
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
        revealed = false;

        transferOwnership(_owner);
    }

    /// @dev Authorization for contract upgrades, only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Adds a new mint phase with optional whitelist.
     * @param price Price per token during the mint phase.
     * @param limit Maximum number of tokens a single address can mint.
     * @param startTime Start time of the mint phase (UNIX timestamp).
     * @param endTime End time of the mint phase (UNIX timestamp).
     * @param whitelistEnabled Whether whitelist is enabled for this phase.
     * @param whitelistedAddresses Optional array of addresses to whitelist.
     */
    function addMintPhase(
        uint128 price,
        uint32 limit,
        uint32 startTime,
        uint32 endTime,
        bool whitelistEnabled,
        address[] calldata whitelistedAddresses
    ) external onlyOwner {
        require(startTime < endTime, "Invalid time range");

        phases.push(PhaseSettings({
            mintPrice: price,
            mintLimit: limit,
            mintStartTime: startTime,
            mintEndTime: endTime,
            whitelistEnabled: whitelistEnabled
        }));

        uint256 phaseIndex = phases.length - 1;

        if (whitelistEnabled) {
            for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
                phaseWhitelist[phaseIndex][whitelistedAddresses[i]] = true;
            }
        }
    }

    /**
     * @notice Updates the whitelist for a specific phase.
     * @param phaseIndex Index of the minting phase to update.
     * @param users List of user addresses to be added or removed from the whitelist.
     * @param status True to add users to the whitelist, false to remove.
     */
    function updateWhitelist(uint256 phaseIndex, address[] calldata users, bool status) external onlyOwner {
        require(phaseIndex < phases.length, "Invalid phase index");
        require(phases[phaseIndex].whitelistEnabled, "Whitelist not enabled for this phase");

        for (uint256 i = 0; i < users.length; i++) {
            phaseWhitelist[phaseIndex][users[i]] = status;
        }
    }

    /**
     * @notice Mint a token during a specific phase.
     * @param phaseIndex Index of the mint phase to mint from.
     * @param tokenId Token ID to mint.
     */
    function mint(uint256 phaseIndex, uint256 tokenId) external payable {
        require(phaseIndex < phases.length, "Invalid phase index");
        PhaseSettings storage phase = phases[phaseIndex];

        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime, "Minting phase inactive");
        require(_totalMinted < maxSupply, "Max supply reached");
        require(msg.value == phase.mintPrice, "Incorrect mint price");
        require(minted[msg.sender] < phase.mintLimit, "Mint limit exceeded");

        if (phase.whitelistEnabled) {
            require(phaseWhitelist[phaseIndex][msg.sender], "Not whitelisted for this phase");
        }

        _totalMinted++;
        minted[msg.sender]++;
        _safeMint(msg.sender, tokenId);

        uint256 royaltyAmount = (msg.value * royaltyPercentage) / 10000;
        distributeRoyalties(royaltyAmount);
        saleRecipient.sendValue(msg.value - royaltyAmount);
    }

    /**
     * @notice Distributes royalties to the royalty recipients.
     * @param totalAmount The total royalty amount to distribute.
     */
    function distributeRoyalties(uint256 totalAmount) internal {
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            royaltyRecipients[i].sendValue((totalAmount * royaltyShares[i]) / 10000);
        }
    }

    /**
     * @notice Returns the token URI, using the pre-reveal URI if the collection is not revealed.
     * @param tokenId The token ID to query.
     * @return The URI string for the token.
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
     * @param newBaseTokenURI The new base URI to set for the revealed collection.
     */
    function revealCollection(string memory newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
        revealed = true;
    }

    /**
     * @notice Retrieves the details of a specific minting phase.
     * @param phaseIndex The index of the phase to retrieve.
     * @return mintPrice The price per token during the phase.
     * @return mintLimit The per-user mint limit during the phase.
     * @return mintStartTime The start time of the phase (UNIX timestamp).
     * @return mintEndTime The end time of the phase (UNIX timestamp).
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
     * @notice Returns the total number of minting phases.
     * @return The total number of phases in the contract.
     */
    function getTotalPhases() external view returns (uint256) {
        return phases.length;
    }
}
