require("@nomicfoundation/hardhat-toolbox");

require("dotenv").config(); // For loading environment variables

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    bscTestnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545/`, // BSC Testnet RPC URL
      accounts: [process.env.DEPLOYER_PRIVATE_KEY] // Your wallet private key
    }
  },
  etherscan: {
    apiKey: process.env.BSCSCAN_API_KEY // Your BscScan API key
  }
};
