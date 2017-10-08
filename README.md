<img src="https://s3-us-west-2.amazonaws.com/dharma-assets/DharmaLogoGoldbyBlack.png"  width=200/>

------------

#### Background
[Collateralized Debt Obligations](https://en.wikipedia.org/wiki/Collateralized_debt_obligation#Subprime_mortgage_boom) (also known as CDOs) have rightfully earned notoriety for the prominent role they played in the subprime mortgage crisis.  Nonetheless, their use is still extremely prevalent today, and they fill an important demand in the structured finance market.  For a lucid, short explanation of the mechanics of a CDO, see [here](https://www.khanacademy.org/economics-finance-domain/core-finance/derivative-securities/cdo-tutorial/v/collateralized-debt-obligation-overview).  One of the most damning diagnoses of the role CDOs played in the subprime mortgage crisis was the opaqueness of the underlying assets -- buyers of such credit products, to a certain extent, had to take rating agencies at their word for their assessment of the assets' solvency.  Enter Dharma Protocol -- with open standards for cryptographic debt assets, we have the ability to create 'Glass CDOs' -- tokenized CDOs where the payout mechanics are powered by a smart contract, and the assets comprising a CDO are fully auditable and transparent on chain.

#### Goal

Build a contract that packages 3 loans in the Dharma Protocol into a two-tranched CDO -- parameters outlined below.  For purposes of this exercise, assume the tranches themselves don't have differing interest rates associated with them.

#### Structure

- **Total CDO Tokens**: 1,000,000
- **Senior Tranche**: 600,000 Tokens
- **Mezzanine Tranche**: 400,000 Tokens

#### Expectations

- [ ] Develop a smart contract in Solidity called `CDO.sol` that encompasses all of the business logic of a 2-tranched CDO containing 3 loans, where the senior tranche is **paid out first** until it's been made whole for 60% of the principal + interest, and the mezzanine tranche is **paid out second** with the remainder of the principal + interest.
- [ ] Each tranche should be a superset of the ERC20 standard -- i.e. ownership in a tranche should be denominated by a standard crypto token.
- [ ] Develop a suite of tests for the above functionality

#### Evaluation Criteria

- Is the CDO functional?  Are payouts handled correctly?
- Is a reasonable degree of testing included?
- Is code readable and clean?
- Are functions properly decomposed such that concerns are separated?

#### Notes and Tips (Read this):

- In `test/utils/LoanFactory.js`, there is a method called `generateTestLoan`.  You should use this method in constructing your tests -- it will abstract away any of the complexity around the loan auctioning process, and give you a fully-funded, ready-to-go loan out the box.
- The CDO contract doesn't have to be generic -- it can be specific to the set of loans you're packaging in it.  Feel free to hard-code things like interest rates and expected principal.
- For this specific assignment, don't worry about including metadata in `CDO.sol` relating to the tranches' interest rates and terms -- I mainly care about seeing the redemption functionality work correctly.
- You can choose whatever principal and interest amounts you see fit for the underlying loans, so long as the math around redemptions functions correctly.
- In looking over the contracts, pay particular attention to `RedeemableTokenLib.sol`.  You will find the functionality herein useful when creating your tranches.
- Though I only want to see 3 loans packaged into this CDO, **the mechanics you've chosen for handling redemptions should theoretically be able to scale up to 1000s of loans**.  Think carefully about the design decisions you make and their implications on the block gas limit.
- If you have any questions or issues, don't hesitate to text me at 9492935907 -- I've only run this interview with a candidate once, and I'm still very much in the process of refining it.


### Setup
---------------
##### Dependencies

Install dependencies:
```
npm install
```

##### Testing

Start `testrpc`:
```
npm run testrpc
```
Run `truffle` tests:
```
npm test
```


### Contract Architecture
---------------

1. [LoanLib.sol](https://github.com/dharmaprotocol/contracts/blob/master/contracts/LoanLib.sol)

A wrapper library for all business logic associated with crowdfunding, administering, and pricing-via-auction any loans issued under the Dharma Protocol.  Loans inherit logic from `RedeemableTokenLib`, and, as such, expose standardized logic for redeeming value from loan repayments on a *pro-rata* basis for debt token holders.  Note that this generic logic is exposed in the form of a library, and that no state is stored in the `LoanLib.sol`.
2. [LoanRegistry.sol](https://github.com/dharmaprotocol/contracts/blob/master/contracts/LoanRegistry.sol)

This contract functions as a factory for creating debt assets in Dharma Protocol, and, in turn, as a registry and store for state and metadata associated with said assets.  The business logic exposed by these assets is inherited from `LoanLib.sol`.


3. [RedeemableTokenLib.sol](https://github.com/dharmaprotocol/contracts/blob/master/contracts/RedeemableTokenLib.sol)

Implements a superset of the [ERC20 token standard](https://theethereum.wiki/w/index.php/ERC20_Token_Standard)'s functionality that allows for what we call "redeemable tokens".  Redeemable tokens are assets where ownership of a token represents a right to *pro rata* cash flows that are generated by the asset.  As an illustrative example, consider a loan as a redeemable token: if an individual holds `X%` of the token supply, and a repayment is made to the loan (i.e. the `totalValueAccrued` is increased by `Y`), that individual will be able to redeem `X%` of the `totalValueAccrued`.  This functionality is inherited by `LoanLib.sol`.

4. [VersionRegister.sol](https://github.com/dharmaprotocol/contracts/blob/master/contracts/VersionRegister.sol)

A centrally managed on-chain registry of the above contracts' deployed addresses as corresponding to the protocol's release version. For the time being, this is a (centralized) mechanism for upgrading the protocol contracts.

5. [SafeMath.sol](https://github.com/dharmaprotocol/contracts/blob/master/contracts/SafeMath.sol)

All of the above contracts use `SafeMath.sol` as a generic library for safe mathematical operations.  The file is part of [OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity)'s fantastic libraries.

6. [Migrations.sol](https://github.com/dharmaprotocol/contracts/blob/master/contracts/Migrations.sol)

Boilerplate migration code used by the truffle framework.
