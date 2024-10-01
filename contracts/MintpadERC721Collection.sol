// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
contract MintpadERC721Collection is ERC721Enumerable, Ownable {
    using Address for address payable;
    using Strings for uint256;
    uint256 public maxSupply;
    string private baseTokenURI;
    string private preRevealURI;
    bool public revealState;
    string private _collectionName;
    string private _collectionSymbol;
    address payable[] public salesRecipients;
    uint256[] public salesShares;
    address payable[] public royaltyRecipients;
    uint256[] public royaltyShares;
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
        require(msg.sender == owner(), "Caller is not the owner");
        _;
    }

    constructor(
        string memory _initialName,
        string memory _initialSymbol,
        uint256 _maxSupply,
        string memory _baseTokenURI,
        string memory _preRevealURI,
        address payable[] memory _salesRecipients,
        uint256[] memory _salesShares,
        address payable[] memory _royaltyRecipients,
        uint256[] memory _royaltyShares,
        uint256 _royaltyPercentage,
        address _owner
    ) ERC721(_initialName, _initialSymbol) Ownable(_owner) {
        require(_royaltyPercentage <= 10000, "");
        require(_salesRecipients.length == _salesShares.length, "");
        require(_royaltyRecipients.length == _royaltyShares.length, "");

        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        preRevealURI = _preRevealURI;
        salesRecipients = _salesRecipients;
        salesShares = _salesShares;
        royaltyRecipients = _royaltyRecipients;
        royaltyShares = _royaltyShares;
        royaltyPercentage = _royaltyPercentage;

        _collectionName = _initialName;
        _collectionSymbol = _initialSymbol;
    }
    function mint(uint256 phaseIndex, uint256 tokenId) external payable {
        PhaseSettings memory phase = phases[phaseIndex];
        require(
            block.timestamp >= phase.mintStartTime && block.timestamp <= phase.mintEndTime, 
            ""
        );
        require(totalSupply() < maxSupply);
        require(msg.value == phase.mintPrice);

        if (phase.whitelistEnabled) {
            require(whitelist[msg.sender]);
            require(whitelistMinted[msg.sender] < phase.mintLimit);
            unchecked { whitelistMinted[msg.sender]++; }
        } else {
            require(publicMinted[msg.sender] < phase.mintLimit);
            unchecked { publicMinted[msg.sender]++; }
        }
        _safeMint(msg.sender, tokenId);
        distributeSales(msg.value);
    }
    function distributeSales(uint256 totalAmount) internal {
        uint256 length = salesRecipients.length;
        for (uint256 i = 0; i < length; ) {
            uint256 share = (totalAmount * salesShares[i]) / 10000;
            salesRecipients[i].sendValue(share);
            unchecked { ++i; }
        }
    }
    function updateRecipients(
        address payable[] calldata _newRecipients,
        uint256[] calldata _newShares,
        bool isSales
    ) external onlyDeployer {
        require(_newRecipients.length == _newShares.length);

        if (isSales) {
            _updateArray(_newRecipients, _newShares, salesRecipients, salesShares);
        } else {
            _updateArray(_newRecipients, _newShares, royaltyRecipients, royaltyShares);
        }
    }
 function _updateArray(
    address payable[] calldata _newRecipients, 
    uint256[] calldata _newShares, 
    address payable[] storage recipients, 
    uint256[] storage shares
) internal {
    while (recipients.length > 0) {
        recipients.pop();
    }
    while (shares.length > 0) {
        shares.pop();
    }
    for (uint256 i = 0; i < _newRecipients.length; ) {
        recipients.push(_newRecipients[i]);
        shares.push(_newShares[i]);
        unchecked { ++i; }
    }
}
    function setRoyalties(address payable _recipient, uint256 _royaltyPercentage) external onlyDeployer {
        require(_royaltyPercentage <= 10000);
        delete royaltyRecipients;
        delete royaltyShares;
        royaltyRecipients.push(_recipient);
        royaltyShares.push(10000);
        royaltyPercentage = _royaltyPercentage;
    }
    function setWhitelist(address[] calldata _addresses, bool _status) external onlyDeployer {
        uint256 length = _addresses.length;
        for (uint256 i = 0; i < length; ) {
            whitelist[_addresses[i]] = _status;
            unchecked { ++i; }
        }
    }
    function setRevealState(bool _state, string memory _newBaseURI) external onlyDeployer {
        revealState = _state;
        if (_state) {
            baseTokenURI = _newBaseURI;
        }
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return revealState ? baseTokenURI : preRevealURI;
    }
     function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }
}
