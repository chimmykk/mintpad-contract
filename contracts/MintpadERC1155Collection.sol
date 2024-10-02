// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

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

    uint256 public maxSupply;
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
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;
    mapping(uint256 => uint256) private _tokenSupply;

    modifier onlyDeployer() {
        require(msg.sender == owner(), "Not the deployer");
        _;
    }

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
        require(_royaltyPercentage <= 10000, "Invalid royalty percentage");
        require(_royaltyRecipients.length == _royaltyShares.length, "Mismatched recipients and shares");

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

    function mint(uint256 phaseIndex, uint256 tokenId, uint256 amount) external payable {
        PhaseSettings memory phase = phases[phaseIndex];
        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime, "Minting not active");
        require(_tokenSupply[tokenId] + amount <= maxSupply, "Exceeds max supply");
        require(msg.value == phase.mintPrice * amount, "Incorrect minting price");

        if (phase.whitelistEnabled) {
            require(whitelist[msg.sender], "Not whitelisted");
            require(whitelistMinted[msg.sender] + amount <= phase.mintLimit, "Mint limit exceeded");
            unchecked { whitelistMinted[msg.sender] += amount; }
        } else {
            require(publicMinted[msg.sender] + amount <= phase.mintLimit, "Mint limit exceeded");
            unchecked { publicMinted[msg.sender] += amount; }
        }

        _mint(msg.sender, tokenId, amount, "");
        _tokenSupply[tokenId] += amount;
        distributeSales(msg.value);
    }

    function addMintPhase(
        uint256 _mintPrice,
        uint256 _mintLimit,
        uint256 _mintStartTime,
        uint256 _mintEndTime,
        bool _whitelistEnabled
    ) external onlyDeployer {
        require(_mintStartTime < _mintEndTime, "Invalid phase time");

        phases.push(PhaseSettings({
            mintPrice: _mintPrice,
            mintLimit: _mintLimit,
            mintStartTime: _mintStartTime,
            mintEndTime: _mintEndTime,
            whitelistEnabled: _whitelistEnabled
        }));
    }

    function distributeSales(uint256 totalAmount) internal {
        saleRecipient.sendValue(totalAmount);
    }

    function distributeRoyalties(uint256 totalAmount) internal {
        uint256 length = royaltyRecipients.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 share = (totalAmount * royaltyShares[i]) / 10000; 
            royaltyRecipients[i].sendValue(share);
        }
    }

    function setRoyaltyRecipients(
        address payable[] calldata _newRecipients,
        uint256[] calldata _newShares,
        uint256 _royaltyPercentage
    ) external onlyDeployer {
        require(_newRecipients.length == _newShares.length);
        require(_newShares.length > 0, "No shares provided");
        require(_royaltyPercentage <= 10000, "Invalid royalty percentage");

        royaltyRecipients = _newRecipients;
        royaltyShares = _newShares;
        royaltyPercentage = _royaltyPercentage;
    }
    function setWhitelist(address[] calldata _addresses, bool _status) external onlyDeployer {
        uint256 length = _addresses.length;
        for (uint256 i = 0; i < length; i++) {
            whitelist[_addresses[i]] = _status;
        }
    }

    function removeFromWhitelist(address _address) external onlyDeployer {
        whitelist[_address] = false;
    }

    function setRevealState(bool _state, string memory _newBaseURI) external onlyDeployer {
        revealState = _state;
        if (_state) {
            baseTokenURI = _newBaseURI;
        }
    }
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_tokenSupply[tokenId] > 0, "Token does not exist");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }
      function getTotalPhases() external view returns (uint256) {
        return phases.length;
    }

    function _baseURI() internal view returns (string memory) {
        return revealState ? baseTokenURI : preRevealURI;
    }
}
