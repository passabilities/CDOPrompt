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

  before(async () => {
    cdo = await CDO.deployed();
    loan = await Loan.deployed();
    loanFactory = new LoanFactory(loan);
  })

  describe('CDO', () => {
    const rate = 0.2;
    const totalWorth = web3.toBigNumber(web3.toWei(7.2, 'ether'))
    let uuid;
    let cdoLoanIds;

    before(async () => {
      let one = await loanFactory.generateTestLoan(accounts, web3.toWei(1, 'ether'), rate)
      let two = await loanFactory.generateTestLoan(accounts, web3.toWei(2, 'ether'), rate)
      let three = await loanFactory.generateTestLoan(accounts, web3.toWei(3, 'ether'), rate)
      cdoLoanIds = _.map([one, two, three], 'uuid')

      // Transfer investor tokens to CDO contract
      // Not sure if this is right place to do transfer
      await loan.transfer(one.uuid, cdo.address, await loan.balanceOf.call(one.uuid, accounts[0]), { from: accounts[0] })
      await loan.transfer(two.uuid, cdo.address, await loan.balanceOf.call(two.uuid, accounts[0]), { from: accounts[0] })
      await loan.transfer(three.uuid, cdo.address, await loan.balanceOf.call(three.uuid, accounts[0]), { from: accounts[0] })

      uuid = web3.sha3(uuidV4())
      await cdo.create(uuid, cdoLoanIds, { from: accounts[1] })
    })

    describe('#create()', () => {
      it('should create a CDO from loans', async () => {
        try {
          let cdoWorth = await cdo.getTotalWorth.call(uuid)
          expect(totalWorth.equals(cdoWorth)).to.be(true)
        } catch (err) {
          util.assertThrowMessage(err);
        }
      })

      it('should payout senior tranche', async () => {
        const repayment = web3.toWei(0.5, 'ether')

        try {
          await loan.periodicRepayment(cdoLoanIds[0],
            { value: repayment })

          await cdo.withdrawRepayment(uuid, cdoLoanIds[0], { from: accounts[0] })

          let repaid = await cdo.getTrancheAmountRepaidByIndex.call(uuid, 0)
          expect(repaid.equals(web3.toBigNumber(repayment))).to.be(true)

          console.log(web3.eth.getBalance(accounts[1]))
          await cdo.redeemTrancheValueByIndex(uuid, 0, { from: accounts[1] })
          console.log(web3.eth.getBalance(accounts[1]))
        } catch (err) {
          util.assertThrowMessage(err);
        }
      })
    })
  })
})
