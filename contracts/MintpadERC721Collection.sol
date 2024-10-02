// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title MintpadERC721Collection
 * @dev ERC721 contract that supports phases, royalties, and reveal functionality for NFTs.
 */
contract MintpadERC721Collection is ERC721, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint256 public maxSupply;
    uint256 private _totalMinted;
    string private baseTokenURI;
    string private preRevealURI;
    bool public revealState;

    address payable public saleRecipient;
    uint16 public royaltyPercentage; // Royalty in basis points (1% = 100)
    address payable[] public royaltyRecipients;
    uint16[] public royaltyShares; // Royalty shares in basis points

    struct PhaseSettings {
        uint128 mintPrice;
        uint32 mintLimit;
        uint32 mintStartTime;
        uint32 mintEndTime;
        bool whitelistEnabled;
    }

    PhaseSettings[] public phases;
    mapping(address => uint32) public minted; // Tracks how many NFTs an address has minted
    mapping(address => bool) public whitelisted;

    
    /**
     * @dev Modifier that allows only the deployer (contract owner) to call certain functions.
     */
    modifier onlyDeployer() {
        require(msg.sender == owner());
        _;
    }


    /**
     * @dev Constructor that initializes the ERC721 collection with the given parameters.
     * @param _name The name of the collection.
     * @param _symbol The symbol of the collection.
     * @param _maxSupply Maximum number of tokens that can be minted.
     * @param _baseTokenURI The base URI after reveal.
     * @param _preRevealURI The base URI before reveal.
     * @param _saleRecipient Address to receive the sale proceeds.
     * @param _royaltyRecipients Array of addresses that receive royalty shares.
     * @param _royaltyShares Corresponding royalty share (in basis points) for each recipient.
     * @param _royaltyPercentage Total royalty percentage (in basis points).
     * @param _owner The address that will be set as the owner of the contract.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        string memory _baseTokenURI,
        string memory _preRevealURI,
        address payable _saleRecipient,
        address payable[] memory _royaltyRecipients,
        uint16[] memory _royaltyShares,
        uint16 _royaltyPercentage,
        address _owner
    ) ERC721(_name, _symbol) Ownable(_owner) {
        require(_royaltyPercentage <= 10000);
        require(_royaltyRecipients.length == _royaltyShares.length);

        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        preRevealURI = _preRevealURI;
        saleRecipient = _saleRecipient;
        royaltyRecipients = _royaltyRecipients;
        royaltyShares = _royaltyShares;
        royaltyPercentage = _royaltyPercentage;
    }

    /**
     * @notice Mints a new token during an active phase.
     * @param phaseIndex The index of the minting phase.
     * @param tokenId The ID of the token to mint.
     */
    function mint(uint256 phaseIndex, uint256 tokenId) external payable {
        PhaseSettings memory phase = phases[phaseIndex];

        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime, "Minting not active");
        require(_totalMinted < maxSupply);
        require(msg.value == phase.mintPrice);
        require(minted[msg.sender] < phase.mintLimit);
        require(!phase.whitelistEnabled || whitelisted[msg.sender]);

        _totalMinted++;
        minted[msg.sender]++;
        _safeMint(msg.sender, tokenId);

        uint256 royaltyAmount = (msg.value * royaltyPercentage) / 10000;
        distributeRoyalties(royaltyAmount);
        saleRecipient.sendValue(msg.value - royaltyAmount);
    }

    /**
     * @notice Distributes the royalty payments to the respective recipients.
     * @param amount The total amount of royalties to distribute.
     */
    function distributeRoyalties(uint256 amount) internal {
        uint256 length = royaltyRecipients.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 share = (amount * royaltyShares[i]) / 10000;
            royaltyRecipients[i].sendValue(share);
        }
    }

    /**
     * @notice Adds a new minting phase to the contract.
     * @param price The price per mint during this phase.
     * @param limit The maximum number of mints per address for this phase.
     * @param startTime The start time of the phase (UNIX timestamp).
     * @param endTime The end time of the phase (UNIX timestamp).
     * @param whitelistEnabled Whether the whitelist is active during this phase.
     */
    function addMintPhase(uint128 price, uint32 limit, uint32 startTime, uint32 endTime, bool whitelistEnabled) external onlyOwner {
        require(startTime < endTime);
        phases.push(PhaseSettings(price, limit, startTime, endTime, whitelistEnabled));
    }

    /**
     * @notice Sets the reveal state of the collection and optionally updates the base URI.
     * @param state The new reveal state (true = revealed, false = hidden).
     * @param newURI The new base URI to set if the collection is revealed.
     */
    function setRevealState(bool state, string memory newURI) external onlyOwner {
        revealState = state;
        if (state) {
            baseTokenURI = newURI;
        }
    }

    /**
     * @notice Updates the maximum supply of the collection.
     * @param increment The amount to increase the max supply by.
     */
    function updateMaxSupply(uint256 increment) external onlyOwner {
        require(increment > 0);
        maxSupply += increment;
    }

    /**
     * @notice Manages the whitelist by adding or removing multiple users in a batch.
     * @param users The addresses to add or remove from the whitelist.
     * @param status The new whitelist status (true = add, false = remove).
     */
    function manageWhitelist(address[] calldata users, bool status) external onlyOwner {
        uint256 length = users.length;
        for (uint256 i = 0; i < length; i++) {
            whitelisted[users[i]] = status;
        }
    }

    /**
     * @dev Internal function to return the base URI, depending on the reveal state.
     */
    function _baseURI() internal view override returns (string memory) {
        return revealState ? baseTokenURI : preRevealURI;
    }

    /**
     * @notice Returns the URI for a given token ID.
     * @param tokenId The ID of the token to retrieve the URI for.
     * @return The token URI string.
     */
     function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }
}
