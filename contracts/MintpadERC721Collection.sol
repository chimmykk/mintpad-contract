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
    mapping(address => bool) public whitelisted;
    constructor(
        string memory _initialName, string memory _initialSymbol,
        uint256 _maxSupply, string memory _baseTokenURI, address _owner,
        address payable _saleRecipient, address payable[] memory _royaltyRecipients, 
        uint16[] memory _royaltyShares, uint16 _royaltyPercentage
    ) ERC721(_initialName, _initialSymbol) Ownable(_owner) {
        require(_royaltyPercentage <= 10000 && 
                _royaltyRecipients.length == _royaltyShares.length, "");
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        saleRecipient = _saleRecipient;
        royaltyRecipients = _royaltyRecipients;
        royaltyShares = _royaltyShares;
        royaltyPercentage = _royaltyPercentage;
    }

    function mint(uint256 phaseIndex, uint256 tokenId) external payable {
        PhaseSettings memory phase = phases[phaseIndex];
        require(block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime);
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

    function addMintPhase(uint128 price, uint32 limit, uint32 startTime, uint32 endTime, bool whitelistEnabled) external onlyOwner {
        require(startTime < endTime, "");
        phases.push(PhaseSettings(price, limit, startTime, endTime, whitelistEnabled));
    }

    function manageWhitelist(address[] calldata users, bool status) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whitelisted[users[i]] = status;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }
}
