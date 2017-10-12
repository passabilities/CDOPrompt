pragma solidity ^0.4.8;

import "./SafeMath.sol";
import "./RedeemableTokenLib.sol";

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
  }

  function initialize(CDO storage self, bytes32[] loan_ids) {
    self.owner = msg.sender;
    self.loan_ids = loan_ids;

    // Determine tranches total worth
    uint totalWorth = 6 ether;
    totalWorth = totalWorth.add(totalWorth.mul(4).div(100)); // 4% interest
    self.seniorTranche.totalWorth = totalWorth.mul(6).div(10); // 60%
    self.mezzanineTranche.totalWorth = totalWorth.mul(4).div(10); // 40%

    self.seniorTranche.token.totalSupply = seniorSupply;
    self.seniorTranche.token.balances[msg.sender] = seniorSupply;

    self.mezzanineTranche.token.totalSupply = mezzanineSupply;
    self.mezzanineTranche.token.balances[msg.sender] = mezzanineSupply;
  }

}
