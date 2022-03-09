import { deployments, ethers } from 'hardhat';
import { Contract } from 'ethers';
import { PhanzNFTV2, MockFeedsNFTSticker } from '../types';
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

export const deployPhanzNFTV2 = async (params: any[]) => {
  return await deployContract<PhanzNFTV2>('PhanzNFTV2', params);
};

export const getPhanzNFTV2Deployment = async (): Promise<PhanzNFTV2> => {
  return (await ethers.getContractAt(
    ContractId.PhanzNFTV2,
    (
      await deployments.get(ContractId.PhanzNFTV2)
    ).address
  )) as PhanzNFTV2;
};

export const deployMockFeedsNFTSticker = async () => {
  return await deployContract<MockFeedsNFTSticker>('MockFeedsNFTSticker', []);
};
