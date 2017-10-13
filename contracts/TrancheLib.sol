pragma solidity ^0.4.8;

import "./SafeMath.sol";
import "./RedeemableTokenLib.sol";
import "./LoanRegistry.sol";

library TrancheLib {

  using SafeMath for uint;
  using RedeemableTokenLib for RedeemableTokenLib.Accounting;

  struct Tranche {
    RedeemableTokenLib.Accounting token;
    uint intrestRate;
  }

  struct TrancheData {
    uint totalSupply;
    uint intrestRate;
  }

  function repay(Tranche storage self, uint amount) {
    self.token.totalValueAccrued = self.token.totalValueAccrued.add(amount);
  }

  function getAmountRepaid(Tranche storage self) returns (uint) {
    return self.token.totalValueAccrued;
  }

}
