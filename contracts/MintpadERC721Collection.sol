// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
/**
 * @title MintpadERC721Collection
 * @dev @This contract deploys individual ERC721 NFT collection contracts with customizable parameters.
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
    uint16 public royaltyPercentage;

    struct PhaseSettings {
        uint128 mintPrice;        // Mint price for the phase
        uint32 mintLimit;         // Per user mint limit for the phase
        uint32 mintStartTime;     // Phase start time (UNIX timestamp)
        uint32 mintEndTime;       // Phase end time (UNIX timestamp)
        bool whitelistEnabled;    // Whether this phase requires whitelist
    }

    PhaseSettings[] public phases; // Array of phases
    mapping(uint256 => mapping(address => bool)) public phaseWhitelist; // Whitelist mapping for each phase (phaseIndex => user => status)
    mapping(address => uint32) public minted; // Tracks the number of tokens minted per address

    /// @notice Initializes the contract with the basic settings
    function initialize(
        string memory name_, string memory symbol_, uint256 _maxSupply,
        string memory _baseTokenURI, string memory _preRevealURI,
        address _owner, address payable _saleRecipient,
        address payable[] memory _royaltyRecipients, uint16[] memory _royaltyShares,
        uint16 _royaltyPercentage
    ) initializer public {
        __ERC721_init(name_, symbol_);
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
        revealed = false;
        transferOwnership(_owner);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Adds a new mint phase with an optional whitelist
    /// @param price Price per token during this phase
    /// @param limit Max number of tokens that can be minted per address
    /// @param startTime Start time of the phase (UNIX timestamp)
    /// @param endTime End time of the phase (UNIX timestamp)
    /// @param whitelistEnabled Whether the phase requires whitelisting
    /// @param whitelistedAddresses Optional array of addresses to whitelist (only if whitelistEnabled is true)
    function addMintPhase(
        uint128 price, uint32 limit, uint32 startTime, uint32 endTime, bool whitelistEnabled, address[] calldata whitelistedAddresses
    ) external onlyOwner {
        require(startTime < endTime, "Invalid time range");

        // Push the new phase settings into the `phases` array
        phases.push(PhaseSettings({
            mintPrice: price,
            mintLimit: limit,
            mintStartTime: startTime,
            mintEndTime: endTime,
            whitelistEnabled: whitelistEnabled
        }));

        uint256 phaseIndex = phases.length - 1;

        // Add whitelisted addresses to the phase's whitelist if whitelistEnabled is true
        if (whitelistEnabled) {
            for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
                phaseWhitelist[phaseIndex][whitelistedAddresses[i]] = true;
            }
        }
    }

    /// @notice Updates the whitelist for a specific phase
    /// @param phaseIndex Index of the minting phase to update
    /// @param users List of user addresses to be added or removed from the whitelist
    /// @param status Whether to add (true) or remove (false) the addresses from the whitelist
    function updateWhitelist(uint256 phaseIndex, address[] calldata users, bool status) external onlyOwner {
        require(phaseIndex < phases.length, "Invalid phase index");
        require(phases[phaseIndex].whitelistEnabled, "Whitelist not enabled for this phase");

        for (uint256 i = 0; i < users.length; i++) {
            phaseWhitelist[phaseIndex][users[i]] = status;
        }
    }

    /// @notice Mint a token based on a specific phase
    /// @param phaseIndex Index of the phase to mint from
    /// @param tokenId Token ID to mint
    function mint(uint256 phaseIndex, uint256 tokenId) external payable {
        require(phaseIndex < phases.length, "Invalid phase index");
        PhaseSettings storage phase = phases[phaseIndex];

        // Phase time validation
        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime, "Minting phase inactive");
        require(_totalMinted < maxSupply, "Max supply reached");

        // Mint price validation
        require(msg.value == phase.mintPrice, "Incorrect mint price");

        // Per-user mint limit validation
        require(minted[msg.sender] < phase.mintLimit, "Mint limit exceeded");

        // Whitelist validation if enabled
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

    /// @notice Distributes royalties to the royalty recipients
    /// @param totalAmount The total royalty amount to be distributed
    function distributeRoyalties(uint256 totalAmount) internal {
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            royaltyRecipients[i].sendValue((totalAmount * royaltyShares[i]) / 10000);
        }
    }

    /// @notice Returns the token URI, using the pre-reveal URI if not revealed
    /// @param tokenId Token ID for which the URI is being queried
    /// @return Token URI string
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");

        if (!revealed) {
            return preRevealURI;
        }

        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }

    /// @notice Allows the owner to reveal the collection by setting the actual base URI
    /// @param newBaseTokenURI The new base URI to use for the revealed collection
    function revealCollection(string memory newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
        revealed = true;
    }

    /// @notice Retrieves details of a specific mint phase
    /// @param phaseIndex The index of the minting phase
    /// @return mintPrice Price per token in this phase
    /// @return mintLimit Maximum number of tokens a user can mint during this phase
    /// @return mintStartTime Start time of the minting phase
    /// @return mintEndTime End time of the minting phase
    /// @return whitelistEnabled Whether whitelist is enabled for this phase
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

    /// @notice Returns the total number of mint phases
    /// @return The total number of phases in the contract
    function getTotalPhases() external view returns (uint256) {
        return phases.length;
    }
}
