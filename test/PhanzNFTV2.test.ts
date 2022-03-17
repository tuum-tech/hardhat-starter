import { expect } from 'chai';
import { ethers } from 'hardhat';

import { runTestSuite, TestVars, oldTokenIds, swapCount, latestTime } from './lib';

runTestSuite('PhantzNFTV2', (vars: TestVars) => {
  it('meta', async () => {
    const {
      PhantzNFTV2,
      accounts: [admin, bob, frank, alice],
    } = vars;

    await PhantzNFTV2.initialize(oldTokenIds);
    await PhantzNFTV2.connect(frank.signer).mint(alice.address, {
      value: ethers.utils.parseEther('0.1'),
    });

    expect(await PhantzNFTV2.balanceOf(alice.address)).to.be.equal(1);
    expect(await PhantzNFTV2.tokenURI(1)).to.be.eq(
      'ipfs://QmUaG9DJMQprYoSWXp3X1V1YMS5E37pjt4MkQGpQtgZkeK/1.json'
    );
  });

  describe('Mint', async () => {
    it('reverted cases', async () => {
      const {
        PhantzNFTV2,
        accounts: [admin, bob, frank, alice],
      } = vars;

      await expect(PhantzNFTV2.connect(frank.signer).mint(frank.address)).to.be.revertedWith(
        'Should mint NFTs for swap first.'
      );

      await PhantzNFTV2.initialize(oldTokenIds);

      await expect(PhantzNFTV2.connect(frank.signer).mint(frank.address)).to.be.revertedWith(
        'Insufficient funds to mint.'
      );

      await expect(
        PhantzNFTV2.connect(frank.signer).mint(alice.address, {
          value: ethers.utils.parseEther('0.01'),
        })
      ).to.be.revertedWith('Insufficient funds to mint.');
    });

    it('success cases', async () => {
      const {
        PhantzNFTV2,
        accounts: [admin, bob, frank, alice],
      } = vars;

      await PhantzNFTV2.initialize(oldTokenIds);

      const newTokenURI = `ipfs://QmUaG9DJMQprYoSWXp3X1V1YMS5E37pjt4MkQGpQtgZkeK/${
        swapCount + 1
      }.json`;

      await expect(
        PhantzNFTV2.connect(frank.signer).mint(alice.address, {
          value: ethers.utils.parseEther('0.1'),
        })
      )
        .to.emit(PhantzNFTV2, 'Minted')
        .withArgs(swapCount + 1, alice.address, newTokenURI, frank.address);
    });
  });

  describe('Swap', async () => {
    it('reverted cases', async () => {
      const {
        PhantzNFTV2,
        FeedsNFTSticker,
        accounts: [admin, oldNFTOwner, frank, alice],
      } = vars;

      expect(await FeedsNFTSticker.balanceOf(oldNFTOwner.address, oldTokenIds[0])).to.be.equal(1);

      // try swap without minting 690 NFTs
      await expect(PhantzNFTV2.swap(1)).to.be.revertedWith('Should mint NFTs for swap first.');
      await PhantzNFTV2.initialize(oldTokenIds);

      // try swap with invalid otkneID
      await expect(PhantzNFTV2.swap(1)).to.be.revertedWith('Not swappable tokenID');

      // try swap without approving old NFTs
      await expect(PhantzNFTV2.swap(oldTokenIds[0])).to.be.revertedWith(
        'Should approve contract first'
      );

      // try swap without old NFTs
      await FeedsNFTSticker.setApprovalForAll(PhantzNFTV2.address, true);
      await expect(PhantzNFTV2.swap(oldTokenIds[0])).to.be.revertedWith('No NFT to swap');
    });

    it('success cases', async () => {
      const {
        PhantzNFTV2,
        FeedsNFTSticker,
        accounts: [admin, oldNFTOwner],
      } = vars;

      await PhantzNFTV2.initialize(oldTokenIds);

      // approve first to burn old NFT
      await FeedsNFTSticker.connect(oldNFTOwner.signer).setApprovalForAll(
        PhantzNFTV2.address,
        true
      );
      expect(await FeedsNFTSticker.isApprovedForAll(oldNFTOwner.address, PhantzNFTV2.address)).to.be
        .true;

      // do swap
      await expect(PhantzNFTV2.connect(oldNFTOwner.signer).swap(oldTokenIds[0]))
        .to.emit(PhantzNFTV2, 'Swapped')
        .withArgs(oldNFTOwner.address, oldTokenIds[0], 1, (await latestTime()) + 1);

      // check old NFT
      expect(await FeedsNFTSticker.balanceOf(oldNFTOwner.address, oldTokenIds[0])).to.be.equal(0);

      // check new NFT
      expect(await PhantzNFTV2.balanceOf(oldNFTOwner.address)).to.be.equal(1);
    });
  });
});
