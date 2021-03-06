require("@babel/register")({
  ignore: [/node_modules/]
});
require("@babel/polyfill");
require("ts-node/register");

// if (process.env.NODE_ENV !== 'production') { // https://codeburst.io/process-env-what-it-is-and-why-when-how-to-use-it-effectively-505d0b2831e7
require("dotenv").load();
// }
const HDWalletProvider = require("truffle-hdwallet-provider");
const PrivateKeyProvider = require("truffle-hdwallet-provider-privkey");

const mnemonic = process.env.MNEMONIC;
const privateKey = process.env.PRIVATE_KEY;

const infura_api = process.env.INFURA_API;
console.log({ mnemonic, privateKey, infura_api });

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!

  networks: {
    develop: {
      // used for 'truffle console' command for debugging purpose. https://truffleframework.com/tutorials/debugger-variable-inspection
      host: "127.0.0.1",
      port: 8545, // "truffle develop" runs on 9545
      network_id: "4447", // Match any network id,
      gas: 8000000
      // from: '0x8ae536FAcb8C89163A0c5A5817Aaa75F65F1bcA6' // should be equal to first address in truffle UI list - address[0]
    },
    ganache: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "4447", // my "ganache " runs with 6000 network_id - configurable
      gas: 8000000,
      from: "0x9689dc4d84b36efa1f02260a90063ae91ef0cbd8"
    },
    test: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      gas: 8000000
    },
    coverage: {
      host: "127.0.0.1",
      network_id: "*", // eslint-disable-line camelcase
      port: 8555,
      gas: 0xfffffffffff,
      gasPrice: 0x01
    },
    mainnet: {
      provider: function() {
        return new HDWalletProvider(
          mnemonic,
          "https://mainnet.infura.io/v3/" + infura_api,
          0,
          10
        );
      },
      network_id: 1,
      skipDryRun: true,
      gas: 8000000,
      gasPrice: 10000000000
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(
          mnemonic,
          "https://ropsten.infura.io/v3/" + infura_api,
          0,
          10
        );
      },
      gas: 8000000,
      gasPrice: 40000000000,
      network_id: 3,
      skipDryRun: true
    },
    kovan: {
      provider: function() {
        return new HDWalletProvider(
          mnemonic,
          "https://kovan.infura.io/v3/" + infura_api,
          0,
          10
        );
      },
      network_id: 42,
      gas: 8000000,
      skipDryRun: true,
      gasPrice: 2000000000 //2 gwei
    },
    fuse: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://rpc.fusenet.io/", 0, 10);
      },
      network_id: 122,
      gas: 8500000,
      skipDryRun: true,
      gasPrice: 2000000000 //1 gwei
    },
    staging: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://rpc.fusenet.io/", 0, 10);
      },
      network_id: 122,
      gas: 8500000,
      skipDryRun: true,
      gasPrice: 2000000000 //1 gwei
    },
    production: {
      provider: function() {
        return new PrivateKeyProvider([privateKey], "https://rpc.fusenet.io/");
      },
      network_id: 122,
      gas: 8500000,
      skipDryRun: true,
      gasPrice: 2000000000 //1 gwei
    }
  },
  mocha: {
    reporter: "eth-gas-reporter",
    reporterOptions: {
      currency: "USD"
    }
  },
  compilers: {
    solc: {
      version: "0.5.4",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  },
  test_file_extension_regexp: /.*\.ts$/
};
