import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

import { config } from '../helpers/constant';

// deploy/0-deploy-PhantzNFTV2.ts
const deployPhantzNFTV2: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { deployer } = await getNamedAccounts();

  await deploy('PhantzNFTV2', {
    from: deployer,
    args: [
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

export default deployPhantzNFTV2;
deployPhantzNFTV2.tags = ['PhantzNFTV2'];
