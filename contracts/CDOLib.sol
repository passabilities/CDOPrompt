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
    bool exists;
    bytes32[] loan_ids;
    TrancheLib.Tranche[] tranches;
    uint totalWorth;
  }

}
