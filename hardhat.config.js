require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      viaIR: true
    }
  },
  networks: {
    hardhat: {
      chainId: 1337,
      accounts: {
        mnemonic: "test test test test test test test test test test test junk",
        count: 20
      }
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 1337
    },
    sepolia: {
      url: process.env.SEPOLIA_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  },
  paths: {
    root: "./",
    sources: "./contracts",
    tests: "./testes",
    cache: "./cache",
    artifacts: "./artefatos"
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "BRL"
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};