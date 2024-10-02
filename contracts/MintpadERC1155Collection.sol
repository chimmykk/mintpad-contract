// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract MintpadERC1155Collection is ERC1155, Ownable {
    using Address for address payable;
    using Strings for uint256;

    struct PhaseSettings {
        uint256 mintPrice;
        uint256 mintLimit;
        uint256 mintStartTime;
        uint256 mintEndTime;
        bool whitelistEnabled;
    }
     string private _collectionName;
    string private _collectionSymbol;

    uint256 public maxSupply;
    string private baseTokenURI;
    string private preRevealURI;
    bool public revealState;
    address payable public saleRecipient; 
    address payable[] public royaltyRecipients; 
    uint256[] public royaltyShares;
    uint256 public royaltyPercentage; 
    PhaseSettings[] public phases;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;
    mapping(uint256 => uint256) private _tokenSupply;

    constructor(
        
        string memory _initialName, string memory _initialSymbol,
        uint256 _maxSupply, string memory _baseTokenURI,
        string memory _preRevealURI, address payable _saleRecipient,
        address payable[] memory _royaltyRecipients, uint256[] memory _royaltyShares,
        uint256 _royaltyPercentage, address _owner
    ) ERC1155(_baseTokenURI) Ownable(_owner) {
        require(_royaltyPercentage <= 10000 && _royaltyRecipients.length == _royaltyShares.length);
        maxSupply = _maxSupply; baseTokenURI = _baseTokenURI; preRevealURI = _preRevealURI;
        saleRecipient = _saleRecipient; royaltyRecipients = _royaltyRecipients; 
        royaltyShares = _royaltyShares; royaltyPercentage = _royaltyPercentage;
        _collectionName = _initialName;
        _collectionSymbol = _initialSymbol;
    }

    function mint(uint256 phaseIndex, uint256 tokenId, uint256 amount) external payable {
        PhaseSettings memory phase = phases[phaseIndex];
        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime &&
                _tokenSupply[tokenId] + amount <= maxSupply && msg.value == phase.mintPrice * amount);
        
        if (phase.whitelistEnabled) {
            require(whitelist[msg.sender] && whitelistMinted[msg.sender] + amount <= phase.mintLimit);
            unchecked { whitelistMinted[msg.sender] += amount; }
        } else {
            require(publicMinted[msg.sender] + amount <= phase.mintLimit);
            unchecked { publicMinted[msg.sender] += amount; }
        }

        _mint(msg.sender, tokenId, amount, ""); _tokenSupply[tokenId] += amount;
        uint256 royaltyAmount = (msg.value * royaltyPercentage) / 10000;
        distributeRoyalties(royaltyAmount); saleRecipient.sendValue(msg.value);
    }

    function distributeRoyalties(uint256 totalAmount) internal {
        for (uint256 i = 0; i < royaltyRecipients.length; ) {
            royaltyRecipients[i].sendValue((totalAmount * royaltyShares[i]) / 10000);
            unchecked { ++i; }
        }
    }

    function setRoyaltyRecipients(address payable[] calldata _newRecipients, uint256[] calldata _newShares) external onlyOwner {
        require(_newRecipients.length == _newShares.length && _newShares.length > 0);
        royaltyRecipients = _newRecipients; royaltyShares = _newShares;
    }

    function setWhitelist(address[] calldata _addresses, bool _status) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; ) {
            whitelist[_addresses[i]] = _status; unchecked { ++i; }
        }
    }

    function addMintPhase(uint128 price, uint32 limit, uint32 startTime, uint32 endTime, bool whitelistEnabled) external onlyOwner {
        require(startTime < endTime);
        phases.push(PhaseSettings(price, limit, startTime, endTime, whitelistEnabled));
    }

    function setRevealState(bool _state, string memory _newBaseURI) external onlyOwner {
        revealState = _state; if (_state) baseTokenURI = _newBaseURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_tokenSupply[tokenId] > 0);
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function updateMaxSupply(uint256 increment) external onlyOwner {
        require(increment > 0);
        maxSupply += increment;
    }

    function _baseURI() internal view returns (string memory) {
        return revealState ? baseTokenURI : preRevealURI;
    }
}
