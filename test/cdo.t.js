import _ from 'lodash';
import uuidV4 from 'uuid/v4';
import expect from 'expect.js';

import LoanFactory from './utils/LoanFactory';
import { web3, util } from './init';
import { CDOCreated } from './utils/CDOEvents'

const Loan = artifacts.require("./LoanRegistry.sol");
const CDO = artifacts.require("./CDO.sol");
contract("CDO", (accounts) => {

  let cdo;
  let loan;
  let loanFactory;

  const creator = accounts[0]
  const rate = 0.2
  let totalWorth
  let uuid = web3.sha3(uuidV4())
  let cdoLoanIds

  before(async () => {
    cdo = await CDO.deployed();
    loan = await Loan.deployed();
    loanFactory = new LoanFactory(loan);

    totalWorth = web3.toBigNumber(web3.toWei(7.2, 'ether'))
    let one = await loanFactory.generateTestLoan(accounts, web3.toWei(1, 'ether'), rate)
    let two = await loanFactory.generateTestLoan(accounts, web3.toWei(2, 'ether'), rate)
    let three = await loanFactory.generateTestLoan(accounts, web3.toWei(3, 'ether'), rate)
    cdoLoanIds = _.map([one, two, three], 'uuid')

    // Transfer investor tokens to CDO contract
    // Not sure if this is right place to do transfer
    await loan.transfer(one.uuid, cdo.address, await loan.balanceOf.call(one.uuid, accounts[0]), { from: accounts[0] })
    await loan.transfer(two.uuid, cdo.address, await loan.balanceOf.call(two.uuid, accounts[0]), { from: accounts[0] })
    await loan.transfer(three.uuid, cdo.address, await loan.balanceOf.call(three.uuid, accounts[0]), { from: accounts[0] })
  })

  describe('#create()', () => {
    it('should create a CDO from loans', async () => {
      try {
        await cdo.create(uuid, cdoLoanIds, { from: creator })
      } catch (err) {
        util.assertThrowMessage(err);
      }
    })

    it('should give CDO creator all tokens', async () => {
      const totalSupply = await cdo.totalTrancheSupply.call()

      try {
        let balance = web3.toBigNumber(0)
        let numTranches = await cdo.getNumTranches.call(uuid)
        for(let i = 0; i < numTranches; i++) {
          balance = balance.add(await cdo.getTrancheBalanceOfByIndex.call(uuid, i, creator))
        }

        expect(web3.toBigNumber(balance).equals(totalSupply)).to.be(true)
      } catch (err) {
        util.assertThrowMessage(err)
      }
    })

    it('should be worth loan amount plus intrest', async () => {
      try {
        let cdoWorth = await cdo.getTotalWorth.call(uuid)
        expect(totalWorth.equals(cdoWorth)).to.be(true)
      } catch (err) {
        util.assertThrowMessage(err)
      }
    })

    it('should throw error on duplicate UUID', async () => {
      try {
        await cdo.create(uuid, cdoLoanIds, { from: accounts[0] })
        expect().fail("should throw error");
      } catch (err) {
        util.assertThrowMessage(err);
      }
    })
  })

  describe('#withdrawRepayment()', () => {
    it('should throw error if investor tries to redeem tranche value before loans repaid', async () => {
      try {
        await cdo.withdrawRepayment(uuid, cdoLoanIds[0])

        expect().fail('should throw error')
      } catch (err) {
        util.assertThrowMessage(err)
      }
    })

    it('should withdraw loan repayments to CDO contract and give tranches value', async () => {
      const loan1Repayment = web3.toWei((1 + (1 * rate)), 'ether')
      const loan2Repayment = web3.toWei((2 + (2 * rate)), 'ether')
      const loan3Repayment = web3.toWei((3 + (3 * rate)), 'ether')

      const beforeBalance = web3.eth.getBalance(cdo.address)
      const loansWorth = web3.toBigNumber(loan1Repayment).add(web3.toBigNumber(loan2Repayment)).add(web3.toBigNumber(loan3Repayment))

      try {
        await loan.periodicRepayment(cdoLoanIds[0], { value: loan1Repayment })
        await loan.periodicRepayment(cdoLoanIds[1], { value: loan2Repayment })
        await loan.periodicRepayment(cdoLoanIds[2], { value: loan3Repayment })

        await cdo.withdrawRepayment(uuid, cdoLoanIds[0])
        await cdo.withdrawRepayment(uuid, cdoLoanIds[1])
        await cdo.withdrawRepayment(uuid, cdoLoanIds[2])

        expect(beforeBalance.add(loansWorth).equals(web3.eth.getBalance(cdo.address))).to.be(true)

        let numTranches = await cdo.getNumTranches.call(uuid)
        for(let i = 0; i < numTranches; i++) {
          let repaid = await cdo.getTrancheAmountRepaidByIndex.call(uuid, i)
          let worth = await cdo.getTrancheTotalWorthByIndex.call(uuid, i)
          expect(repaid.equals(worth)).to.be(true)
        }
      } catch (err) {
        util.assertThrowMessage(err)
      }
    })

    it('should allow investor to redeem loan repayments', async () => {
      try {
        let beforeBalance = web3.eth.getBalance(accounts[0])
        let redeemable = await cdo.getTrancheRedeemableValueByIndex.call(uuid, 0)
        await cdo.redeemTrancheValueByIndex(uuid, 0, { from: accounts[0] })
        expect(beforeBalance.add(redeemable).equals(web3.eth.getBalance(accounts[0])))
      } catch (err) {
        util.assertThrowMessage(err);
      }
    })
  })
})
