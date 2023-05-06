require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-etherscan");
require("solidity-coverage");
require("dotenv").config();
const {
  GOERLI_URL,
  POLYGON_MUMBAI,
  ETHERSCAN_API,
  PRIVATE_KEY,
  COINMARKETCAP_API,
  MUMBAI_KEY,
} = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [{ version: "0.8.12" }, { version: "0.6.6" }],
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },

  defaultNetwork: "hardhat",
  networks: {
    goerli: {
      url: GOERLI_URL,
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 5,
      blockConfirmations: 1,
    },
    mumbai: {
      url: POLYGON_MUMBAI,
      accounts: [`0x${MUMBAI_KEY}`],
      chainId: 80001,
      blockConfirmations: 1,
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
      chainId: 31337,
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API,
  },
  gasReporter: {
    enabled: true,
    outputFile: "gas-reporter.txt",
    noColors: true,
    currency: "USD",
    coinmarketcap: COINMARKETCAP_API,
    token: "MATIC",
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    user: {
      default: 1,
    },
  },
};
