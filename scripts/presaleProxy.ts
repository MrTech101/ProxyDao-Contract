import { BigNumber } from "ethers";
import { upgrades, ethers } from "hardhat";
import "@nomiclabs/hardhat-etherscan";

interface DeploymentOptions {
  bscDao: string;
  bscDaoPrice: string;
  affiliatePercentage: string;
  minAllocation: BigNumber;
  maxAllocation: BigNumber;
  purchaseCap: BigNumber;
}

async function main(deploymentOptions: DeploymentOptions) {
  let {
    bscDao,
    bscDaoPrice,
    affiliatePercentage,
    minAllocation,
    maxAllocation,
    purchaseCap,
  } = deploymentOptions || {};

  let UpgradablePresaleProxy = await ethers.getContractFactory(
    "Presale"
  );
  let Presale = await upgrades.deployProxy(
    UpgradablePresaleProxy,
    [
      bscDao,
      bscDaoPrice,
      affiliatePercentage,
      minAllocation,
      maxAllocation,
      purchaseCap,
    ],
    {
      unsafeAllow: ["state-variable-assignment"] ,
      initializer: "_upgradablePreSale",
      kind:"transparent"
    }
  );

  await Presale.deployed();

  console.log(`bscDao Presale Contract Address is ${Presale.address}`);
}

main({
  bscDao: "0xbFB6E9C33168D53Dc27144Dbff177E366bf509c5", // bsc dao address
  bscDaoPrice: "2500000000000000", // bsc per bnb for eg 0.0025 * 1m
  affiliatePercentage: "1000000", // for eg 1% denotes to 1m
  minAllocation: BigNumber.from("2500000000000000"), // in wei
  maxAllocation: BigNumber.from("500000000000000000"), // in wei
  purchaseCap: BigNumber.from("10000000000000000000000"), // in wei
}).catch((err) => {
  console.log(err.message);
  process.exit(0);
});
