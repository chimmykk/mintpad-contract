// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract MintpadERC721Collection is ERC721Enumerable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint256 public mintPrice;
    uint256 public maxSupply;
    string private baseTokenURI;
    address payable public recipient;

    uint256 public mintStartTime;
    uint256 public mintEndTime;

    uint256 public royaltyPercentage;
    address payable public royaltyRecipient;

    enum MintPhase { None, Public, Whitelist }
    MintPhase public currentMintPhase;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistMinted;

    uint256 public publicMintLimit;
    uint256 public whitelistMintLimit;

    uint256 public publicPhaseSupply;
    uint256 public whitelistPhaseSupply;

    modifier onlyDeployer() {
        require(msg.sender == owner(), "No");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 _mintPrice,
        uint256 _maxSupply,
        string memory _baseTokenURI,
        address payable _recipient,
        address payable _royaltyRecipient,
        uint256 _royaltyPercentage,
        address owner
    ) ERC721(name, symbol) Ownable(owner) {
        require(_royaltyPercentage <= 10000);

        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        recipient = _recipient;
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    function mint(uint256 tokenId) external payable {
        require(totalSupply() < maxSupply);
        require(msg.value == mintPrice);
        require(block.timestamp >= mintStartTime && block.timestamp <= mintEndTime);

        if (currentMintPhase == MintPhase.Whitelist) {
            require(whitelist[msg.sender]);
            require(whitelistMinted[msg.sender] < whitelistMintLimit);
            whitelistMinted[msg.sender]++;
        } else if (currentMintPhase == MintPhase.Public) {
            require(publicMintLimit == 0 || balanceOf(msg.sender) < publicMintLimit);
        } else {
            revert("error");
        }

        recipient.sendValue(msg.value);
        _safeMint(msg.sender, tokenId);
    }

    function setBaseURI(string memory _baseTokenURI) external onlyDeployer {
        baseTokenURI = _baseTokenURI;
    }

    function setMintPhase(
        uint256 _mintStartTime,
        uint256 _mintEndTime,
        MintPhase _mintPhase,
        uint256 _phaseSupply,
        uint256 _phaseMintPrice,
        uint256 _phaseMintLimit
    ) external onlyDeployer {
        require(_phaseSupply > 0);
        require(_phaseSupply <= maxSupply - totalSupply());
        require(_phaseMintPrice > 0);
        require(_phaseMintLimit > 0);

        mintStartTime = _mintStartTime;
        mintEndTime = _mintEndTime;
        currentMintPhase = _mintPhase;
        mintPrice = _phaseMintPrice;

        if (currentMintPhase == MintPhase.Public) {
            publicPhaseSupply = _phaseSupply;
            publicMintLimit = _phaseMintLimit;
        } else if (currentMintPhase == MintPhase.Whitelist) {
            whitelistPhaseSupply = _phaseSupply;
            whitelistMintLimit = _phaseMintLimit;
        } else {
            revert("Invalid");
        }
    }
    function setWhitelist(address[] memory _addresses, bool _status) external onlyDeployer {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _status;
        }
    }

    function setMintLimits(uint256 _publicMintLimit, uint256 _whitelistMintLimit) external onlyDeployer {
        publicMintLimit = _publicMintLimit;
        whitelistMintLimit = _whitelistMintLimit;
    }
    function setRoyalties(address payable _royaltyRecipient, uint256 _royaltyPercentage) external onlyDeployer {
        require(_royaltyPercentage <= 10000);
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    function setRecipient(address payable _recipient) external onlyDeployer {
        recipient = _recipient;
    }

    function setMintPrice(uint256 _mintPrice) external onlyDeployer {
        mintPrice = _mintPrice;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0));
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }
}
