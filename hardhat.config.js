require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config(); // For loading environment variables

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,  // You can adjust the runs to optimize for size (lower value) or gas efficiency (higher value)
      },
    },
  },
  networks: {
    taikohekla: {
      url: `https://taiko-hekla.blockpi.network/v1/rpc/public`, // Taiko Helka RPC URL
      accounts: [process.env.PRIVATE_KEY] // Use environment variable for wallet private key
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY] // Use environment variable for wallet private key
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY, // Your Etherscan API key
    customChains: [
      {
        network: "taikohelka",
        chainId: 167009,
        urls: {
          apiURL: "https://api-hekla.taikoscan.io/api",
          browserURL: "https://hekla.taikoscan.io/"
        }
      }
    ]
  }
};
