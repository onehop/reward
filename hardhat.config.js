/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');
const { accounts, bscscanApiKey } = require('./secrets.json');

module.exports = {
  solidity: {
    //version: "0.8.4",
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }, //hop
      },
    ],
  },
  defaultNetwork: "localhost",
  networks: {
    testnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      accounts: accounts,
      gas: 20000000
    },
    mainnet: {
      url: `https://bsc-dataseed.binance.org/`,
      accounts: accounts,
      gas: 20000000
    },
  },
  etherscan: {
    apiKey: bscscanApiKey
  }
};
