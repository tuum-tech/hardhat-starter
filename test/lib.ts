import { deployments, ethers, getNamedAccounts } from 'hardhat';
import { Signer, Wallet } from 'ethers';
import { assert } from 'chai';

import { PhantzNFTV2, MockFeedsNFTSticker } from '../types';
import { EthereumAddress } from '../helpers/types';
import { deployPhantzNFTV2, deployMockFeedsNFTSticker } from '../helpers/contract';
import { config, oldTokenIds } from '../helpers/constant';

export interface IAccount {
  address: EthereumAddress;
  signer: Signer;
  privateKey: string;
}

export interface TestVars {
  PhantzNFTV2: PhantzNFTV2;
  FeedsNFTSticker: MockFeedsNFTSticker;
  accounts: IAccount[];
  team: IAccount;
}

const testVars: TestVars = {
  PhantzNFTV2: {} as PhantzNFTV2,
  FeedsNFTSticker: {} as MockFeedsNFTSticker,
  accounts: {} as IAccount[],
  team: {} as IAccount,
};

export const swapCount = oldTokenIds.length;

export const latestTime = async () => (await ethers.provider.getBlock('latest')).timestamp;

export const premintSwapNFTs = async (vars: TestVars) => {
  const { PhantzNFTV2 } = vars;
  const oldTokenIds1 = oldTokenIds.slice(0, swapCount / 2);
  await PhantzNFTV2.premint(oldTokenIds1);

  const oldTokenIds2 = oldTokenIds.slice(swapCount / 2, swapCount + 1);
  await PhantzNFTV2.premint(oldTokenIds2);
};

const setupOtherTestEnv = async (vars: TestVars) => {
  // setup other test env
  const FeedsNFTSticker = await deployMockFeedsNFTSticker();
  await FeedsNFTSticker.initialize();

  const PhantzNFTV2 = await deployPhantzNFTV2([
    config.auction,
    config.marketplace,
    config.bundleMarketplace,
    config.platformFee,
    config.feeReceipient,
    FeedsNFTSticker.address,
    swapCount,
  ]);

  const {
    accounts: [admin, oldNFTOwner, frank, alice],
  } = vars;

  for (let i = 0; i < swapCount; i++) {
    await FeedsNFTSticker.connect(oldNFTOwner.signer).mint(oldTokenIds[i], 1, '', '10000', '');
  }

  return {
    FeedsNFTSticker,
    PhantzNFTV2,
  };
};

export function runTestSuite(title: string, tests: (arg: TestVars) => void) {
  describe(title, function () {
    before(async () => {
      // we manually derive the signers address using the mnemonic
      // defined in the hardhat config
      const mnemonic = 'test test test test test test test test test test test junk';

      testVars.accounts = await Promise.all(
        (
          await ethers.getSigners()
        ).map(async (signer, index) => ({
          address: await signer.getAddress(),
          signer,
          privateKey: ethers.Wallet.fromMnemonic(mnemonic, `m/44'/60'/0'/0/${index}`).privateKey,
        }))
      );
      assert.equal(
        new Wallet(testVars.accounts[0].privateKey).address,
        testVars.accounts[0].address,
        'invalid mnemonic or address'
      );

      const { team } = await getNamedAccounts();
      // address used in performing admin actions in InterestRateModel
      testVars.team = testVars.accounts.find(
        (x) => x.address.toLowerCase() === team.toLowerCase()
      ) as IAccount;
    });

    beforeEach(async () => {
      const setupTest = deployments.createFixture(
        async ({ deployments, getNamedAccounts, ethers }, options) => {
          await deployments.fixture(); // ensure you start from a fresh deployments
        }
      );

      await setupTest();
      const vars = await setupOtherTestEnv(testVars);
      Object.assign(testVars, vars);
    });

    tests(testVars);
  });
}
