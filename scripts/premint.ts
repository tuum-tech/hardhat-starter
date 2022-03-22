// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat

import { ethers } from 'hardhat';
import { oldTokenIds } from '../helpers/constant';

async function main() {
  const PhantzNFTV2Contract = await ethers.getContractFactory('PhantzNFTV2');
  const contract = await PhantzNFTV2Contract.attach('0x0f684b9f2c9c43d97dff54cb3f50ad383d7e8f8f');

  const oldTokenIds1 = oldTokenIds.slice(0, 345);
  await contract.premint(oldTokenIds1);
  console.log('first 345 NFTs are minted to swap');

  const oldTokenIds2 = oldTokenIds.slice(345, 691);
  await contract.premint(oldTokenIds2);
  console.log('second 345 NFTs are minted to swap');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
