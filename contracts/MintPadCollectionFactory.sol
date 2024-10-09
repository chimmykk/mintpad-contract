// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { MintpadERC721Collection } from "./MintpadERC721Collection.sol";
import { MintpadERC1155Collection } from "./MintpadERC1155Collection.sol";

contract MintpadCollectionFactory {
    address public master721Contract;
    address public master1155Contract;

    event CollectionDeployed(address indexed collectionAddress, string name, string symbol, bool isERC721);

    constructor(address _master721Contract, address _master1155Contract) {
        master721Contract = _master721Contract;
        master1155Contract = _master1155Contract;
    }

    /**
     * @notice Deploys a new MintpadERC721Collection contract.
     * @param name_ Name of the NFT collection.
     * @param symbol_ Symbol for the NFT collection.
     * @param _saleRecipient Address to receive sale proceeds.
     * @param _royaltyRecipients List of royalty recipients.
     * @param _royaltyShares List of royalty share percentages (in basis points).
     * @param _royaltyPercentage Royalty percentage for ERC2981 (in basis points).
     * @return collectionAddress The address of the deployed collection.
     */
    function deployERC721Collection(
        string memory name_,
        string memory symbol_,
        address payable _saleRecipient,
        address payable[] memory _royaltyRecipients,
        uint256[] memory _royaltyShares,
        uint96 _royaltyPercentage
    ) external returns (address collectionAddress) {
        // Create a new ERC1967Proxy that points to the master ERC721 contract
        ERC1967Proxy proxy = new ERC1967Proxy(
            master721Contract,
            abi.encodeWithSignature(
                "initialize(string,string,address,address payable[],uint256[],uint96)",
                name_,
                symbol_,
                _saleRecipient,
                _royaltyRecipients,
                _royaltyShares,
                _royaltyPercentage
            )
        );

        collectionAddress = address(proxy);
        emit CollectionDeployed(collectionAddress, name_, symbol_, true);
    }

    /**
     * @notice Deploys a new MintpadERC1155Collection contract.
     * @param name_ Name of the NFT collection.
     * @param symbol_ Symbol for the NFT collection.
     * @param _maxSupply Maximum supply of tokens.
     * @param _baseTokenURI Metadata base URI after reveal.
     * @param _preRevealURI Metadata URI before reveal.
     * @param _saleRecipient Address to receive sale proceeds.
     * @param _royaltyRecipients List of royalty recipients.
     * @param _royaltyShares List of royalty share percentages (in basis points).
     * @param _royaltyPercentage Royalty percentage for ERC2981 (in basis points).
     * @return collectionAddress The address of the deployed collection.
     */
    function deployERC1155Collection(
        string memory name_,
        string memory symbol_,
        uint256 _maxSupply,
        string memory _baseTokenURI,
        string memory _preRevealURI,
        address payable _saleRecipient,
        address payable[] memory _royaltyRecipients,
        uint256[] memory _royaltyShares,
        uint96 _royaltyPercentage
    ) external returns (address collectionAddress) {
        // Create a new ERC1967Proxy that points to the master ERC1155 contract
        ERC1967Proxy proxy = new ERC1967Proxy(
            master1155Contract,
            abi.encodeWithSignature(
                "initialize(string,string,uint256,string,string,address,address payable[],uint256[],uint96)",
                name_,
                symbol_,
                _maxSupply,
                _baseTokenURI,
                _preRevealURI,
                _saleRecipient,
                _royaltyRecipients,
                _royaltyShares,
                _royaltyPercentage
            )
        );

        collectionAddress = address(proxy);
        emit CollectionDeployed(collectionAddress, name_, symbol_, false);
    }
}
