import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

import { config } from '../helpers/constant';

// deploy/0-deploy-PhanzNFTV2.ts
const deployPhanzNFTV2: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { deployer } = await getNamedAccounts();

  await deploy('PhanzNFTV2', {
    from: deployer,
    args: [
      config.name,
      config.symbol,
      config.auction,
      config.marketplace,
      config.bundleMarketplace,
      config.platformFee,
      config.feeReceipient,
      config.feedNFTSticker,
      config.swapCount,
    ],
    log: true,
  });
};

export default deployPhanzNFTV2;
deployPhanzNFTV2.tags = ['PhanzNFTV2'];
