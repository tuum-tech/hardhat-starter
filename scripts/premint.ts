// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat

import { ethers } from 'hardhat';
import { oldTokenIds } from '../helpers/constant';

async function main() {
  // FeedsNFTSticker
  const FeedsNFTSticker = await ethers.getContractFactory('MockFeedsNFTSticker');
  const feedsNFTSticker = await FeedsNFTSticker.attach(
    '0x020c7303664bc88ae92cE3D380BF361E03B78B81'
  );

  console.log(
    await feedsNFTSticker.balanceOf(
      '0xabB6D4a1015e291b1bc71e7e56ff2c9204665b07',
      '46528210778950666215236991069464782653137148637860766160708804757362426446907'
    ),
    await feedsNFTSticker.isApprovedForAll(
      '0xabB6D4a1015e291b1bc71e7e56ff2c9204665b07',
      '0xfDdE60866508263e30C769e8592BB0f8C3274ba7'
    )
  );

  const PhantzNFTV2Contract = await ethers.getContractFactory('PhantzNFTV2');
  const phantzContract = await PhantzNFTV2Contract.attach(
    '0xfDdE60866508263e30C769e8592BB0f8C3274ba7'
  );

  // Pre-mint 690 NFTS
  for (let i = 0; i < 6; i++) {
    await phantzContract.premint(oldTokenIds.slice(i * 100, (i + 1) * 100));
    console.log(`${i + 1}th 100 NFTs are minted to swap`);
  }

  await phantzContract.premint(oldTokenIds.slice(600, 690));
  console.log('last 690 NFTs are minted');

  // check if mints are available
  console.log('ready To mint?', await phantzContract.readyToMint());

  // check if swap is working
  await phantzContract.swap(
    '46528210778950666215236991069464782653137148637860766160708804757362426446907'
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
