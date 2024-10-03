// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title MintpadERC1155Collection
 * @dev This contract deploys individual ERC1155 NFT collection contracts with customizable parameters.
 */
contract MintpadERC1155Collection is ERC1155Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    using Address for address payable;
    using Strings for uint256; 

    // Struct to store the settings of each minting phase
    struct PhaseSettings {
        uint256 mintPrice;
        uint256 mintLimit;
        uint256 mintStartTime;
        uint256 mintEndTime;
        bool whitelistEnabled;
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

    PhaseSettings[] public phases;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;
    mapping(uint256 => uint256) private _tokenSupply;

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

    function name() public view returns (string memory) {
        return _collectionName;
    }
    function symbol() public view returns (string memory) {
        return _collectionSymbol;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function revealCollection(string memory newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
        revealState = true;
    }

    function addMintPhase(
        uint256 price, 
        uint256 limit, 
        uint256 startTime, 
        uint256 endTime, 
        bool whitelistEnabled
    ) external onlyOwner {
        require(startTime < endTime, "Invalid time range");
        phases.push(PhaseSettings(price, limit, startTime, endTime, whitelistEnabled));
    }

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

        uint256 royaltyAmount = (msg.value * royaltyPercentage) / 10000;
        distributeRoyalties(royaltyAmount);
        saleRecipient.sendValue(msg.value - royaltyAmount);
    }

    function distributeRoyalties(uint256 totalAmount) internal {
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            royaltyRecipients[i].sendValue((totalAmount * royaltyShares[i]) / 10000);
        }
    }

    function manageWhitelist(address[] calldata users, bool status) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = status;
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_tokenSupply[tokenId] > 0, "Token does not exist");

        if (!revealState) {
            return preRevealURI;
        }

        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }

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

    function getTotalPhases() external view returns (uint256) {
        return phases.length;
    }
}
