

# Mintpad V2 Smart Contract

This is a project under development for Mintpad.

Try running some of the following tasks:

```shell
npx hardhat 
npx hardhat run scripts/deploy.js --network hardhat
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
npx harhat compile 
```



## Running Custom Test Suite

To run the custom test suite (`test1`, `test2`, `test3`), follow the steps below:

### 1. Deploy ERC721 and ERC1155 Implementations

Run `test1.js` and `test2.js` to deploy the necessary smart contract implementations.



### 2. Update Implementation Addresses in test3.js
After running `test1.js` and `test2.js`

`Update the implementation addresses in test3.js to reflect the deployed contract addresses:`


`const erc721Implementation = "deployedcontractaddress";`
`const erc1155Implementation = "deployedcontractaddress";`





`Once the addresses are updated, run test3.js `

### 3.  Run for testcases
`npx hardhat test`


