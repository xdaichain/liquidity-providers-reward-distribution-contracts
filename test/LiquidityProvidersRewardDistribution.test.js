const { ether, BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { ethers } = require('ethers');

const LiquidityProvidersRewardDistribution = artifacts.require('LiquidityProvidersRewardDistribution');
const ERC20Mock = artifacts.require('ERC20Mock');

contract('LiquidityProvidersRewardDistribution', accounts => {
  const [owner, distributor] = accounts;

  let distributionContract;
  let stakeToken;

  const initializeMethod = 'initialize(address,address,address)';

  function initialize(...params) {
    if (params.length === 0) {
      params = [
        owner,
        distributor,
        stakeToken.address,
      ];
    }
    return distributionContract.methods[initializeMethod](...params, { from: owner });
  }

  beforeEach(async () => {
    stakeToken = await ERC20Mock.new();
    distributionContract = await LiquidityProvidersRewardDistribution.new();
    await initialize();
    await stakeToken.initialize();
  });

  describe('initialize', () => {
    it('should be set up correctly', async () => {
      expect(await distributionContract.owner()).to.equal(owner);
      expect(await distributionContract.distributor()).to.equal(distributor);
      expect(await distributionContract.token()).to.equal(stakeToken.address);
    });
  });
  describe('distribute', () => {
    let snapshotBlockNumber;
    let liquidityProviders;
    let rewards;
    let total;
    let fee;
    beforeEach(async () => {
      snapshotBlockNumber = new BN(5);
      liquidityProviders = Array(100).fill(null).map(() => ethers.Wallet.createRandom().address);
      rewards = Array(100).fill(null).map(() => ether(String(Math.floor(Math.random() * 10) + 1)));
      total = rewards.reduce((acc, curr) => acc.add(curr), new BN(0));
      fee = ether('1');
    });
    it('should distribute', async () => {
      const contractBalance = ether('1001');
      await stakeToken.mint(distributionContract.address, contractBalance);
      const receipt = await distributionContract.distribute(
        snapshotBlockNumber,
        liquidityProviders,
        rewards,
        fee,
        { from: distributor }
      );
      expectEvent(receipt, 'Distributed', { snapshotBlockNumber, total: total.add(fee), fee });
      expect(receipt.receipt.gasUsed).to.be.lte(3000000);
      const balances = await Promise.all(liquidityProviders.map(provider => stakeToken.balanceOf(provider)));
      rewards.forEach((reward, index) => {
        expect(balances[index]).to.be.bignumber.equal(reward);
      });
      expect(await stakeToken.balanceOf(distributionContract.address)).to.be.bignumber.equal(contractBalance.sub(total).sub(fee));
      expect(await stakeToken.balanceOf(distributor)).to.be.bignumber.equal(fee);
    });
    it('fails if not a distributor', async () => {
      const contractBalance = ether('1000');
      await stakeToken.mint(distributionContract.address, contractBalance);
      await expectRevert(
        distributionContract.distribute(snapshotBlockNumber, liquidityProviders, rewards, fee, { from: accounts[2] }),
        'caller is not the distributor',
      );
    });
    it('fails if the sum of rewards is greater than contract balance', async () => {
      const contractBalance = ether('10');
      await stakeToken.mint(distributionContract.address, contractBalance);
      await expectRevert(
        distributionContract.distribute(snapshotBlockNumber, liquidityProviders, rewards, fee, { from: distributor }),
        'ERC20: transfer amount exceeds balance',
      );
      expect(await stakeToken.balanceOf(distributionContract.address)).to.be.bignumber.equal(contractBalance);
    });
  });
});
