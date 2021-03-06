import { ICeloNetwork, networkNames } from "@ubeswap/hardhat-celo";
import * as fs from "fs";
import { ActionType, HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContracts } from "./001_contracts";

export type DeployFunction = (
  env: HardhatRuntimeEnvironment
) => Promise<{ [contractName: string]: string }>;

const deployers: { [step: string]: DeployFunction } = {
  contracts: deployContracts,
};

const makeConfigPath = (step: string, chainId: ICeloNetwork): string =>
  __dirname +
  `/../../deployments/${step}.${networkNames[chainId]}.addresses.json`;

const writeDeployment = async (
  step: string,
  chainId: ICeloNetwork,
  addresses: Record<string, string>
): Promise<void> => {
  const configPath = makeConfigPath(step, chainId);
  Object.entries(addresses).forEach(([name, addr]) =>
    console.log(`${name}: ${addr}`)
  );
  await fs.promises.writeFile(configPath, JSON.stringify(addresses, null, 2));
};

export const getDeployment = async (
  step: string,
  chainId: ICeloNetwork
): Promise<Record<string, string>> => {
  const configPath = makeConfigPath(step, chainId);
  return JSON.parse((await fs.promises.readFile(configPath)).toString());
};

export const deploy: ActionType<{ step: string }> = async ({ step }, env) => {
  const chainId = await env.celo.kit.connection.chainId();
  const deployer = deployers[step];
  if (!deployer) {
    throw new Error(`Unknown step: ${step}`);
  }
  const result = await deployer(env);
  await writeDeployment(step, chainId, result);
};