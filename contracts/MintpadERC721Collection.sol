// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract MintpadERC721Collection is ERC721, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint256 public maxSupply;
    uint256 private _totalMinted; 
    string private baseTokenURI;
    string private preRevealURI;
    bool public revealState;
    
    address payable public saleRecipient; 
    address payable[] public royaltyRecipients;
    uint16[] public royaltyShares; 
    uint16 public royaltyPercentage; 

    struct PhaseSettings {
        uint128 mintPrice; 
        uint32 mintLimit;  
        uint32 mintStartTime; 
        uint32 mintEndTime; 
        bool whitelistEnabled;
    }

    PhaseSettings[] public phases;
    mapping(address => uint32) public minted; 
    mapping(address => bool) public whitelistedAddresses; // New mapping for whitelisted addresses

    modifier onlyDeployer() {
        require(msg.sender == owner());
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
        uint16[] memory _royaltyShares,
        uint16 _royaltyPercentage,
        address _owner
    ) ERC721(_initialName, _initialSymbol) Ownable(_owner) {
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

    function addMintPhase(
        uint128 _mintPrice,
        uint32 _mintLimit,
        uint32 _mintStartTime,
        uint32 _mintEndTime,
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

    function mint(uint256 phaseIndex, uint256 tokenId) external payable {
        PhaseSettings memory phase = phases[phaseIndex];
        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime, "");
        require(_totalMinted < maxSupply);
        require(msg.value == phase.mintPrice);

        if (phase.whitelistEnabled) {
            require(whitelistedAddresses[msg.sender], "You are not whitelisted");
            require(minted[msg.sender] < phase.mintLimit);
        } else {
            require(minted[msg.sender] < phase.mintLimit);
        }

        unchecked { minted[msg.sender]++; }
        _totalMinted++; 
        _safeMint(msg.sender, tokenId);
        distributeSales(msg.value); 
    }

    function distributeSales(uint256 totalAmount) internal {
        saleRecipient.sendValue(totalAmount);
    }
      function getTotalPhases() external view returns (uint256) {
        return phases.length;
    }


    function distributeRoyalties(uint256 totalAmount) internal {
        uint256 length = royaltyRecipients.length;
        for (uint256 i = 0; i < length; ) {
            uint256 share = (totalAmount * royaltyShares[i]) / 10000;
            royaltyRecipients[i].sendValue(share);
            unchecked { ++i; }
        }
    }
    
    function setSaleRecipient(address payable _newRecipient) external onlyDeployer {
        saleRecipient = _newRecipient;
    }

    function setRoyaltyRecipients(
        address payable[] calldata _newRecipients,
        uint16[] calldata _newShares
    ) external onlyDeployer {
        require(_newRecipients.length == _newShares.length);
        require(_newShares.length > 0);
        delete royaltyRecipients;
        delete royaltyShares;
        royaltyRecipients = _newRecipients;
        royaltyShares = _newShares;
    }

    function setRevealState(bool _state, string memory _newBaseURI) external onlyDeployer {
        revealState = _state;
        if (_state) {
            baseTokenURI = _newBaseURI;
        }
    }
    function addToWhitelist(address _address) external onlyDeployer {
        whitelistedAddresses[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyDeployer {
        whitelistedAddresses[_address] = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return revealState ? baseTokenURI : preRevealURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }
}
