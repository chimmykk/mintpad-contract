// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract UpgradeManager {
    /// @notice Upgrade the proxy to the new implementation contract
    /// @param proxyAddress The address of the proxy contract
    /// @param newImplementation The address of the new implementation (MintpadERC721CollectionV2)
    function upgrade(address proxyAddress, address newImplementation) external {
        // Call the upgradeTo function of the proxy to switch to the new implementation
        (bool success, ) = proxyAddress.call(
            abi.encodeWithSignature("upgradeTo(address)", newImplementation)
        );
        require(success, "Upgrade failed");
    }
}
