// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MintpadLibrary} from "./MintpadLibrary.sol";

contract MintpadERC721Collection is ERC721Enumerable, Ownable {
    using Address for address payable;
    using Strings for uint256;
    using MintpadLibrary for *;

    uint256 public maxSupply;
    string private baseTokenURI;
    address payable public recipient;
    address payable public royaltyRecipient;
    uint256 public royaltyPercentage;

    struct PhaseSettings {
        uint256 mintPrice;
        uint256 mintLimit;
        uint256 mintStartTime;
        uint256 mintEndTime;
        bool whitelistEnabled;
    }

    PhaseSettings[] public phases;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;

    modifier onlyDeployer() {
        require(msg.sender == owner());
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        string memory _baseTokenURI,
        address payable _recipient,
        address payable _royaltyRecipient,
        uint256 _royaltyPercentage,
        address _owner
    ) ERC721(name, symbol) Ownable(_owner) {
        require(_royaltyPercentage <= 10000);
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        recipient = _recipient;
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    function addMintPhase(
        uint256 _mintPrice,
        uint256 _mintLimit,
        uint256 _mintStartTime,
        uint256 _mintEndTime,
        bool _whitelistEnabled
    ) external onlyDeployer {
        require(_mintStartTime < _mintEndTime);
        phases.push(PhaseSettings({
            mintPrice: _mintPrice,
            mintLimit: _mintLimit,
            mintStartTime: _mintStartTime,
            mintEndTime: _mintEndTime,
            whitelistEnabled: _whitelistEnabled
        }));
    }

    function getPhase(uint256 phaseIndex) external view returns (
        uint256 mintPrice,
        uint256 mintLimit,
        uint256 mintStartTime,
        uint256 mintEndTime,
        bool whitelistEnabled
    ) {
        require(phaseIndex < phases.length);
        PhaseSettings memory phase = phases[phaseIndex];
        return (
            phase.mintPrice,
            phase.mintLimit,
            phase.mintStartTime,
            phase.mintEndTime,
            phase.whitelistEnabled
        );
    }

    function getTotalPhases() external view returns (uint256) {
        return phases.length;
    }

    function mint(uint256 phaseIndex, uint256 tokenId) external payable {
        require(phaseIndex < phases.length);
        PhaseSettings memory phase = phases[phaseIndex];

        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime);
        require(totalSupply() < maxSupply);
        require(msg.value == phase.mintPrice);

        if (phase.whitelistEnabled) {
            require(whitelist[msg.sender]);
            require(whitelistMinted[msg.sender] < phase.mintLimit);
            whitelistMinted[msg.sender]++;
        } else {
            require(publicMinted[msg.sender] < phase.mintLimit);
            publicMinted[msg.sender]++;
        }

        recipient.sendValue(msg.value);
        _safeMint(msg.sender, tokenId);
    }

    function setWhitelist(address[] memory _addresses, bool _status) external onlyDeployer {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _status;
        }
    }

    function setRoyalties(address payable _royaltyRecipient, uint256 _royaltyPercentage) external onlyDeployer {
        require(_royaltyPercentage <= 10000);
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    function setRecipient(address payable _recipient) external onlyDeployer {
        recipient = _recipient;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0));
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }
}
