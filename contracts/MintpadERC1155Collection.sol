// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title MintpadERC1155Collection
 * @dev ERC1155 contract for minting a single tokenId with phases, whitelist, and royalty functionality.
 */
contract MintpadERC1155Collection is ERC1155, Ownable {
    using Address for address payable;
    using Strings for uint256;

    struct PhaseSettings {
        uint128 mintPrice;
        uint32 mintLimit;
        uint32 mintStartTime;
        uint32 mintEndTime;
        bool whitelistEnabled;
    }

    uint256 public maxSupply;
    uint256 private _totalMinted;
    string private baseTokenURI;
    string private preRevealURI;
    bool public revealState;

    string private collectionName;
    string private collectionSymbol;

    address payable public saleRecipient;
    address payable[] public royaltyRecipients;
    uint256[] public royaltyShares;
    uint256 public royaltyPercentage;

    PhaseSettings[] public phases;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public minted;
    uint256 private constant TOKEN_ID = 1; 
    uint256 private _tokenSupply;

    /**
     * @dev Modifier that allows only the deployer (contract owner) to call certain functions.
     */
    modifier onlyDeployer() {
        require(msg.sender == owner());
        _;
    }

    /**
     * @dev Contract constructor that initializes the collection with initial parameters.
     * @param _initialName Collection name.
     * @param _initialSymbol Collection symbol.
     * @param _maxSupply Maximum supply of the token.
     * @param _baseTokenURI Base URI for token metadata after reveal.
     * @param _preRevealURI URI for token metadata before reveal.
     * @param _saleRecipient Address to receive sales proceeds.
     * @param _royaltyRecipients List of addresses receiving royalties.
     * @param _royaltyShares Corresponding shares of each royalty recipient.
     * @param _royaltyPercentage Royalty percentage (in basis points).
     * @param _owner Owner of the contract.
     */
    constructor(
        string memory _initialName,
        string memory _initialSymbol,
        uint256 _maxSupply,
        string memory _baseTokenURI,
        string memory _preRevealURI,
        address payable _saleRecipient,
        address payable[] memory _royaltyRecipients,
        uint256[] memory _royaltyShares,
        uint256 _royaltyPercentage,
        address _owner
    ) ERC1155(_baseTokenURI) Ownable(_owner) {
        require(_royaltyPercentage <= 10000);
        require(_royaltyRecipients.length == _royaltyShares.length);

        collectionName = _initialName;
        collectionSymbol = _initialSymbol;

        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        preRevealURI = _preRevealURI;
        saleRecipient = _saleRecipient;
        royaltyRecipients = _royaltyRecipients;
        royaltyShares = _royaltyShares;
        royaltyPercentage = _royaltyPercentage;
    }

    /**
     * @notice Mint tokens during an active phase.
     * @dev Requires the caller to send the correct Ether amount and be within the mint limits.
     * @param phaseIndex The phase in which the caller is minting.
     */
    function mint(uint256 phaseIndex) external payable {
        PhaseSettings memory phase = phases[phaseIndex];
        require(
            block.timestamp >= phase.mintStartTime &&
            block.timestamp <= phase.mintEndTime &&
            _totalMinted < maxSupply &&
            msg.value == phase.mintPrice
        );
        require(
            minted[msg.sender] < phase.mintLimit &&
            (!phase.whitelistEnabled || whitelist[msg.sender])
        );

        _totalMinted++;
        minted[msg.sender]++;
        _mint(msg.sender, TOKEN_ID, 1, "");
        _tokenSupply++;

        uint256 royaltyAmount = (msg.value * royaltyPercentage) / 10000;
        distributeRoyalties(royaltyAmount);
        saleRecipient.sendValue(msg.value - royaltyAmount);
    }

    /**
     * @notice Adds a new mint phase.
     * @param price Price per mint during this phase.
     * @param limit Maximum number of mints per address in this phase.
     * @param startTime Start time of the phase (in UNIX timestamp).
     * @param endTime End time of the phase (in UNIX timestamp).
     * @param whitelistEnabled Whether the whitelist is active for this phase.
     */
    function addMintPhase(uint128 price, uint32 limit, uint32 startTime, uint32 endTime, bool whitelistEnabled) external onlyOwner {
        require(startTime < endTime);
        phases.push(PhaseSettings(price, limit, startTime, endTime, whitelistEnabled));
    }

    /**
     * @notice Manages the whitelist in batches.
     * @param users Array of user addresses to modify in the whitelist.
     * @param status Boolean status (true to add to whitelist, false to remove).
     */
    function manageWhitelist(address[] calldata users, bool status) external onlyOwner {
        uint256 length = users.length;
        for (uint256 i = 0; i < length; i++) {
            whitelist[users[i]] = status;
        }
    }

    /**
     * @notice Distributes the royalty amount to the configured recipients.
     * @param totalAmount The total amount of royalties to distribute.
     */
    function distributeRoyalties(uint256 totalAmount) internal {
        uint256 length = royaltyRecipients.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 share = (totalAmount * royaltyShares[i]) / 10000;
            royaltyRecipients[i].sendValue(share);
        }
    }

    /**
     * @notice Updates the reveal state of the collection and sets the base URI if revealed.
     * @param _state New reveal state.
     * @param _newBaseURI New base URI to use when reveal is active.
     */
    function setRevealState(bool _state, string memory _newBaseURI) external onlyOwner {
        revealState = _state;
        if (_state) {
            baseTokenURI = _newBaseURI;
        }
    }

    /**
     * @notice Returns the token URI for the specified tokenId.
     * @param tokenId The tokenId (only tokenId = 1 is valid).
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenId == TOKEN_ID);
        require(_tokenSupply > 0);
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    /**
     * @notice Internal function to return the base URI depending on reveal state.
     */
    function _baseURI() internal view returns (string memory) {
        return revealState ? baseTokenURI : preRevealURI;
    }

    /**
     * @notice Updates the maximum supply by incrementing the value.
     * @param increment Value to add to the max supply.
     */
    function updateMaxSupply(uint256 increment) external onlyOwner {
        require(increment > 0);
        maxSupply += increment;
    }
}
