// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Mintpad ERC-1155 Collection
 * @dev ERC1155 NFT collection contract with adjustable mint price, max supply, and royalties.
 */
contract MintpadERC1155Collection is ERC1155, Ownable {
    using Address for address payable;
    using Strings for uint256;

    enum MintPhase { None, Public, Whitelist }
    MintPhase public currentMintPhase;

    string public collectionName;
    string public collectionSymbol;
    uint256 public maxSupply;
    uint256 public currentSupply;
    string private baseTokenURI;
    address payable public recipient;

    uint256 public royaltyPercentage;
    address payable public royaltyRecipient;

    struct PhaseSettings {
        uint256 mintPrice;
        uint256 mintLimit;
        uint256 mintStartTime;
        uint256 mintEndTime;
    }

    PhaseSettings public publicPhaseSettings;
    PhaseSettings public whitelistPhaseSettings;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistMinted;

    modifier onlyDeployer() {
        require(msg.sender == owner());
        _;
    }

    constructor(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _baseTokenURI,
        uint256 _maxSupply,
        address payable _recipient,
        address payable _royaltyRecipient,
        uint256 _royaltyPercentage,
        address _owner
    ) ERC1155(_baseTokenURI) Ownable(_owner) {
        require(_royaltyPercentage <= 10000);

        collectionName = _collectionName;
        collectionSymbol = _collectionSymbol;
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        recipient = _recipient;
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    function mint(uint256 id, uint256 amount) external payable {
        require(currentSupply + amount <= maxSupply);

        uint256 mintPrice = getCurrentMintPrice();
        require(msg.value == mintPrice * amount);
        require(block.timestamp >= getMintStartTime() && block.timestamp <= getMintEndTime());

        if (currentMintPhase == MintPhase.Whitelist) {
            require(whitelist[msg.sender]);
            require(whitelistMinted[msg.sender] + amount <= whitelistPhaseSettings.mintLimit);
            whitelistMinted[msg.sender] += amount;
        } else if (currentMintPhase == MintPhase.Public) {
            require(publicPhaseSettings.mintLimit == 0 || balanceOf(msg.sender, id) + amount <= publicPhaseSettings.mintLimit);
        } else {
            revert();
        }

        recipient.sendValue(msg.value);
        _mint(msg.sender, id, amount, "");
        currentSupply += amount;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
        _setURI(baseTokenURI);
    }

    function addMintPhase(
        uint256 _mintPrice,
        uint256 _mintLimit,
        uint256 _mintStartTime,
        uint256 _mintEndTime,
        bool _whitelistEnabled
    ) external onlyOwner {
        require(_mintStartTime < _mintEndTime);

        if (_whitelistEnabled) {
            whitelistPhaseSettings = PhaseSettings({
                mintPrice: _mintPrice,
                mintLimit: _mintLimit,
                mintStartTime: _mintStartTime,
                mintEndTime: _mintEndTime
            });
            currentMintPhase = MintPhase.Whitelist;
        } else {
            publicPhaseSettings = PhaseSettings({
                mintPrice: _mintPrice,
                mintLimit: _mintLimit,
                mintStartTime: _mintStartTime,
                mintEndTime: _mintEndTime
            });
            currentMintPhase = MintPhase.Public;
        }
    }

    function getCurrentMintPrice() public view returns (uint256) {
        if (currentMintPhase == MintPhase.Public) {
            return publicPhaseSettings.mintPrice;
        } else if (currentMintPhase == MintPhase.Whitelist) {
            return whitelistPhaseSettings.mintPrice;
        } else {
            revert();
        }
    }

    function getMintStartTime() public view returns (uint256) {
        if (currentMintPhase == MintPhase.Public) {
            return publicPhaseSettings.mintStartTime;
        } else if (currentMintPhase == MintPhase.Whitelist) {
            return whitelistPhaseSettings.mintStartTime;
        } else {
            revert();
        }
    }

    function getMintEndTime() public view returns (uint256) {
        if (currentMintPhase == MintPhase.Public) {
            return publicPhaseSettings.mintEndTime;
        } else if (currentMintPhase == MintPhase.Whitelist) {
            return whitelistPhaseSettings.mintEndTime;
        } else {
            revert();
        }
    }

    function getPhaseSettings() external view returns (
        uint256 publicMintPrice,
        uint256 publicMintLimit,
        uint256 publicMintStartTime,
        uint256 publicMintEndTime,
        uint256 whitelistMintPrice,
        uint256 whitelistMintLimit,
        uint256 whitelistMintStartTime,
        uint256 whitelistMintEndTime
    ) {
        return (
            publicPhaseSettings.mintPrice,
            publicPhaseSettings.mintLimit,
            publicPhaseSettings.mintStartTime,
            publicPhaseSettings.mintEndTime,
            whitelistPhaseSettings.mintPrice,
            whitelistPhaseSettings.mintLimit,
            whitelistPhaseSettings.mintStartTime,
            whitelistPhaseSettings.mintEndTime
        );
    }

    function setWhitelist(address[] memory _addresses, bool _status) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _status;
        }
    }

    function setMintLimits(uint256 _publicMintLimit, uint256 _whitelistMintLimit) external onlyOwner {
        publicPhaseSettings.mintLimit = _publicMintLimit;
        whitelistPhaseSettings.mintLimit = _whitelistMintLimit;
    }

    function setRoyalties(address payable _royaltyRecipient, uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage <= 10000);
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    function setRecipient(address payable _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(bytes(baseTokenURI).length > 0);
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }
}
