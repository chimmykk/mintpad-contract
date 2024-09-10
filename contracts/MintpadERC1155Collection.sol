// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Mintpad ERC-1155 Template
 * @dev ERC1155 NFT collection contract with adjustable mint price, max supply, and royalties.
 */
contract MintpadERC1155Collection is ERC1155, Ownable {
    using Address for address payable;
    using Strings for uint256;

    enum MintPhase { None, Public, Whitelist }
    MintPhase public currentMintPhase;

    string public collectionName;
    string public collectionSymbol;
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public currentSupply;
    string private baseTokenURI;
    address payable public recipient;

    uint256 public royaltyPercentage;
    address payable public royaltyRecipient;
    uint256 public mintStartTime;
    uint256 public mintEndTime;

    uint256 public publicMintLimit;
    uint256 public whitelistMintLimit;
    
    uint256 public publicPhaseSupply;
    uint256 public whitelistPhaseSupply;

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
        uint256 _mintPrice,
        uint256 _maxSupply,
        address payable _recipient,
        address payable _royaltyRecipient,
        uint256 _royaltyPercentage,
        address _owner
    ) ERC1155(_baseTokenURI) Ownable(_owner) {
        require(_royaltyPercentage <= 10000);

        collectionName = _collectionName;
        collectionSymbol = _collectionSymbol;
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        recipient = _recipient;
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    function mint(uint256 id, uint256 amount) external payable {
        require(currentSupply + amount <= maxSupply);
        require(msg.value == mintPrice * amount);
        require(block.timestamp >= mintStartTime && block.timestamp <= mintEndTime);

        if (currentMintPhase == MintPhase.Whitelist) {
            require(whitelist[msg.sender]);
            require(whitelistMinted[msg.sender] + amount <= whitelistMintLimit);
            whitelistMinted[msg.sender] += amount;
        } else if (currentMintPhase == MintPhase.Public) {
            require(publicMintLimit == 0 || balanceOf(msg.sender, id) + amount <= publicMintLimit);
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

    function setMintPhase(
        uint256 _mintStartTime,
        uint256 _mintEndTime,
        MintPhase _mintPhase
    ) external onlyOwner {
        mintStartTime = _mintStartTime;
        mintEndTime = _mintEndTime;
        currentMintPhase = _mintPhase;
        require(
            (currentMintPhase == MintPhase.Public && publicPhaseSupply > 0 && mintPrice > 0 && publicMintLimit > 0) ||
            (currentMintPhase == MintPhase.Whitelist && whitelistPhaseSupply > 0 && mintPrice > 0 && whitelistMintLimit > 0)
       
        );
    }

    function setMintPhaseSettings(
        uint256 _publicPhaseSupply,
        uint256 _whitelistPhaseSupply,
        uint256 _publicMintLimit,
        uint256 _whitelistMintLimit,
        uint256 _mintPrice
    ) external onlyOwner {
        if (currentMintPhase == MintPhase.Public) {
            require(_publicPhaseSupply > 0);
            require(_publicPhaseSupply <= maxSupply - currentSupply);
            publicPhaseSupply = _publicPhaseSupply;
            publicMintLimit = _publicMintLimit;
            mintPrice = _mintPrice;
        } else if (currentMintPhase == MintPhase.Whitelist) {
            require(_whitelistPhaseSupply > 0);
            require(_whitelistPhaseSupply <= maxSupply - currentSupply);
            whitelistPhaseSupply = _whitelistPhaseSupply;
            whitelistMintLimit = _whitelistMintLimit;
            mintPrice = _mintPrice;
        } else {
            revert();
        }
    }

    function setWhitelist(address[] memory _addresses, bool _status) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _status;
        }
    }

    function setMintLimits(uint256 _publicMintLimit, uint256 _whitelistMintLimit) external onlyOwner {
        publicMintLimit = _publicMintLimit;
        whitelistMintLimit = _whitelistMintLimit;
    }

    function setRoyalties(address payable _royaltyRecipient, uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage <= 10000);
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    function setRecipient(address payable _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(bytes(baseTokenURI).length > 0);
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }
}
