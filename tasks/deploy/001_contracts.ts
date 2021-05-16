import { deployContract } from "@ubeswap/solidity-create2-deployer";
import { DeployFunction } from ".";
import scoracleContract from "../../build/artifacts/contracts/Scoracle.sol/Scoracle.json";
import factoryContract from "../../build/artifacts/contracts/Factory.sol/Factory.json";

const salt = "Tayo'y magsayawan";

export const deployContracts: DeployFunction = async (env) => {
  const [deployer] = env.celo.getSigners();
  if (!deployer) {
    throw new Error("No deployer.");
  }
  const deployerAddress = await deployer.getAddress();
  console.log("Deployer address: " + deployerAddress);

  console.log("Deploying scoracle...");
  const scoracle = await deployContract({
    salt,
    contractBytecode: scoracleContract.bytecode,
    signer: deployer,
    // constructorTypes: ["address"],
    // constructorArgs: [await deployer.getAddress()],
  });

  console.log("Deploying factory...");
  const factory = await deployContract({
    salt,
    contractBytecode: factoryContract.bytecode,
    signer: deployer,
    constructorTypes: ["address"],
    constructorArgs: [scoracle.address],
  });

  return {
    Factory: factory.address,
    Scoracle: scoracle.address,
  };
};