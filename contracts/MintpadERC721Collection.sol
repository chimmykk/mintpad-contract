// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract MintpadERC721Collection is ERC721, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint256 public maxSupply;
    uint256 private _totalMinted;
    string private baseTokenURI;
    string private preRevealURI;
    bool public revealState;

    address payable public saleRecipient;
    uint16 public royaltyPercentage; 
    address payable[] public royaltyRecipients;
    uint16[] public royaltyShares;

    struct PhaseSettings {
        uint128 mintPrice;
        uint32 mintLimit;
        uint32 mintStartTime;
        uint32 mintEndTime;
        bool whitelistEnabled;
    }

    PhaseSettings[] public phases;
    mapping(address => uint32) public minted; 
    mapping(address => bool) public whitelisted;

    constructor(
        string memory _initialName, string memory _initialSymbol,
        uint256 _maxSupply, string memory _baseTokenURI,
        string memory _preRevealURI, address payable _saleRecipient,
        address payable[] memory _royaltyRecipients, uint16[] memory _royaltyShares,
        uint16 _royaltyPercentage, address _owner
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

    function mint(uint256 phaseIndex, uint256 tokenId) external payable {
        PhaseSettings memory phase = phases[phaseIndex];
        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime, "Minting not active");
        require(_totalMinted < maxSupply && msg.value == phase.mintPrice && 
                minted[msg.sender] < phase.mintLimit && 
                (!phase.whitelistEnabled || whitelisted[msg.sender]));

        _totalMinted++;
        minted[msg.sender]++;
        _safeMint(msg.sender, tokenId);

        uint256 royaltyAmount = (msg.value * royaltyPercentage) / 10000;
        distributeRoyalties(royaltyAmount);
        saleRecipient.sendValue(msg.value - royaltyAmount);
    }

    function distributeRoyalties(uint256 totalAmount) internal {
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            royaltyRecipients[i].sendValue((totalAmount * royaltyShares[i]) / 10000);
        }
    }

    function setSaleRecipient(address payable _newRecipient) external onlyOwner {
        saleRecipient = _newRecipient;
    }

    function setRoyaltyRecipients(address payable[] calldata _newRecipients, uint16[] calldata _newShares) external onlyOwner {
        require(_newRecipients.length == _newShares.length && _newShares.length > 0);
        royaltyRecipients = _newRecipients;
        royaltyShares = _newShares;
    }

    function addMintPhase(uint128 price, uint32 limit, uint32 startTime, uint32 endTime, bool whitelistEnabled) external onlyOwner {
        require(startTime < endTime);
        phases.push(PhaseSettings(price, limit, startTime, endTime, whitelistEnabled));
    }

    function setRevealState(bool _state, string memory _newBaseURI) external onlyOwner {
        revealState = _state;
        if (_state) baseTokenURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return revealState ? baseTokenURI : preRevealURI;
    }

    function updateMaxSupply(uint256 increment) external onlyOwner {
        require(increment > 0);
        maxSupply += increment;
    }

    function manageWhitelist(address[] calldata users, bool status) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whitelisted[users[i]] = status;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }
}
