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

  let BscDaoPresaleUpgradeable = await ethers.getContractFactory(
    "BscDaoPresaleUpgradeable"
  );
  let bscDaoPresale = await upgrades.deployProxy(
    BscDaoPresaleUpgradeable,
    [
      bscDao,
      bscDaoPrice,
      affiliatePercentage,
      minAllocation,
      maxAllocation,
      purchaseCap,
    ],
    {
      unsafeAllow: ["state-variable-assignment"],
      initializer: "__BscDaoPresaleUpgradeable_init",
      kind: "transparent"
    }
  );

  await bscDaoPresale.deployed();

  console.log(`bscDao Presale Contract Address is ${bscDaoPresale.address}`);
}

main({
  bscDao: "0x3A90582f1aea54bfe6A27bB4991A734477E08a19", // bsc dao address
  bscDaoPrice: "2500", // bsc per bnb for eg 0.0025 * 1m
  affiliatePercentage: "1000000", // for eg 1% denotes to 1m
  minAllocation: BigNumber.from("200000000000000000"), // in wei
  maxAllocation: BigNumber.from("500000000000000000000"), // in wei
  purchaseCap: BigNumber.from("10000000000000000000000"), // in wei
}).catch((err) => {
  console.log(err.message);
  process.exit(0);
});
