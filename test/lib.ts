import { deployments, ethers, getNamedAccounts } from 'hardhat';
import { Signer, Wallet } from 'ethers';
import { assert } from 'chai';

import { PhanzNFTV2, MockFeedsNFTSticker } from '../types';
import { EthereumAddress } from '../helpers/types';
import { deployPhanzNFTV2, deployMockFeedsNFTSticker } from '../helpers/contract';
import { config, oldTokenIds as allAldTokenIds } from '../helpers/constant';

export interface IAccount {
  address: EthereumAddress;
  signer: Signer;
  privateKey: string;
}

export interface TestVars {
  PhanzNFTV2: PhanzNFTV2;
  FeedsNFTSticker: MockFeedsNFTSticker;
  accounts: IAccount[];
  team: IAccount;
}

const testVars: TestVars = {
  PhanzNFTV2: {} as PhanzNFTV2,
  FeedsNFTSticker: {} as MockFeedsNFTSticker,
  accounts: {} as IAccount[],
  team: {} as IAccount,
};

export const swapCount = 10;

export const oldTokenIds = allAldTokenIds.slice(0, 10);

export const latestTime = async () => (await ethers.provider.getBlock('latest')).timestamp;

const setupOtherTestEnv = async (vars: TestVars) => {
  // setup other test env
  const FeedsNFTSticker = await deployMockFeedsNFTSticker();
  await FeedsNFTSticker.initialize();

  const PhanzNFTV2 = await deployPhanzNFTV2([
    config.name,
    config.symbol,
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
    PhanzNFTV2,
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
