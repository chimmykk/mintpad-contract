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

    struct PhaseSettings {
        uint256 supply;
        uint256 mintPrice;
        uint256 mintLimit;
    }

    mapping(MintPhase => PhaseSettings) public phaseSettings;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistMinted;

    modifier onlyDeployer() {
        require(msg.sender == owner());
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
        address _owner
    ) ERC721(name, symbol) Ownable(_owner) {
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
        require(mintPrice == phaseSettings[currentMintPhase].mintPrice);
        require(block.timestamp >= mintStartTime && block.timestamp <= mintEndTime);

        if (currentMintPhase == MintPhase.Whitelist) {
            require(whitelist[msg.sender]);
            require(whitelistMinted[msg.sender] < phaseSettings[MintPhase.Whitelist].mintLimit);
            whitelistMinted[msg.sender]++;
        } else if (currentMintPhase == MintPhase.Public) {
            require(balanceOf(msg.sender) < phaseSettings[MintPhase.Public].mintLimit);
        } else {
            revert();
        }

        recipient.sendValue(msg.value);
        _safeMint(msg.sender, tokenId);
    }

    function setMintPhaseSettings(
        MintPhase _phase,
        uint256 _supply,
        uint256 _mintLimit,
        uint256 _mintPrice
    ) external onlyDeployer {
        require(_supply > 0);
        require(_supply <= maxSupply - totalSupply());

        phaseSettings[_phase] = PhaseSettings({
            supply: _supply,
            mintPrice: _mintPrice,
            mintLimit: _mintLimit
        });
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
