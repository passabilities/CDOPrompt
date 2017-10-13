pragma solidity ^0.4.8;

import "./SafeMath.sol";
import "./RedeemableTokenLib.sol";
import "./LoanRegistry.sol";

library CDOLib {

  using SafeMath for uint;
  using RedeemableTokenLib for RedeemableTokenLib.Accounting;

  uint constant seniorSupply = 600000;
  uint constant mezzanineSupply = 400000;

  struct Tranche {
    RedeemableTokenLib.Accounting token;
    uint totalWorth;
  }

  struct CDO {
    address owner;
    bytes32[] loan_ids;
    Tranche seniorTranche;
    Tranche mezzanineTranche;
    uint totalWorth;
  }

  // Save data and initialize tranches
  function initialize(CDO storage self, uint totalWorth, bytes32[] loan_ids) {
    self.owner = msg.sender;
    self.totalWorth = totalWorth;
    self.loan_ids = loan_ids;

    self.seniorTranche.totalWorth = totalWorth.mul(6).div(10); // 60%
    self.mezzanineTranche.totalWorth = totalWorth.mul(4).div(10); // 40%

    self.seniorTranche.token.totalSupply = seniorSupply;
    self.seniorTranche.token.balances[msg.sender] = seniorSupply;

    self.mezzanineTranche.token.totalSupply = mezzanineSupply;
    self.mezzanineTranche.token.balances[msg.sender] = mezzanineSupply;
  }

}
