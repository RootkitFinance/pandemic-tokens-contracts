require("@nomiclabs/hardhat-waffle");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.7.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1_000_000,
          },
          metadata: {
            bytecodeHash: 'none',
          },
        },
      }
    ],
  },
  networks: {
    hardhat: {
      accounts: {
        accountsBalance: "100000000000000000000000"
      },
      chainId: 1
    }
  }
};