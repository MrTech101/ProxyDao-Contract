import { HardhatUserConfig } from "hardhat/config";
import { config as dotEnvConfig } from "dotenv";

// plugins
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
import "@openzeppelin/hardhat-upgrades";
require("hardhat-gas-reporter");
dotEnvConfig({ path: ".env" });

const config: HardhatUserConfig = {
  defaultNetwork: "mainnet",
  networks: {
    testnet: {
      url: process.env.BSC_TESTNET_RPC_URL,
      accounts: [process.env.OWNER_PRIV_KEY as string],
      // initialBaseFeePerGas: 10000000000000000,
      // // gas: 80000000000000000,
      // // gasPrice: 80000000000000000
    },
    mainnet: {
      accounts: [process.env.OWNER_PRIV_KEY as string],
      url: process.env.BSC_RPC_URL,
    },
  },
  solidity: {
    version: "0.8.8",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  contractSizer: {
    runOnCompile: true,
    strict: true,
  },
  etherscan: {
    apiKey: process.env.BSC_SCAN_API_KEY,
  },
};

export default config;
