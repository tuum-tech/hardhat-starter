import { deployments, ethers } from 'hardhat';
import { Contract } from 'ethers';
import { PhantzNFTV2, MockFeedsNFTSticker } from '../types';
import { ContractId } from './types';

export const deployContract = async <ContractType extends Contract>(
  contractName: string,
  args: any[],
  libraries?: {}
) => {
  const signers = await hre.ethers.getSigners();
  const contract = (await (
    await hre.ethers.getContractFactory(contractName, signers[0], {
      libraries: {
        ...libraries,
      },
    })
  ).deploy(...args)) as ContractType;

  return contract;
};

export const deployPhantzNFTV2 = async (params: any[]) => {
  return await deployContract<PhantzNFTV2>('PhantzNFTV2', params);
};

export const getPhantzNFTV2Deployment = async (): Promise<PhantzNFTV2> => {
  return (await ethers.getContractAt(
    ContractId.PhantzNFTV2,
    (
      await deployments.get(ContractId.PhantzNFTV2)
    ).address
  )) as PhantzNFTV2;
};

export const deployMockFeedsNFTSticker = async () => {
  return await deployContract<MockFeedsNFTSticker>('MockFeedsNFTSticker', []);
};
