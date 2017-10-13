pragma solidity ^0.4.8;

import "./SafeMath.sol";
import "./RedeemableTokenLib.sol";
import "./LoanRegistry.sol";
import "./TrancheLib.sol";

library CDOLib {

  using SafeMath for uint;
  using RedeemableTokenLib for RedeemableTokenLib.Accounting;
  using TrancheLib for TrancheLib.Tranche;

  struct CDO {
    bytes32[] loan_ids;
    TrancheLib.Tranche[] tranches;
  }

  // Save data and initialize tranches
  function initialize(CDO storage self, bytes32[] loan_ids, TrancheLib.TrancheData[] trancheData) {
    self.loan_ids = loan_ids;

    // Initialize each tranche
    self.tranches.length = trancheData.length;
    for(uint i = 0; i < trancheData.length; i++) {
      uint supply = trancheData[i].totalSupply
      self.tranches[i].token.totalSupply = supply;
      self.tranches[i].token.balances[msg.sender] = supply;

      self.tranches[i].intrestRate = trancheData[i].intrestRate;
    }
  }

}
