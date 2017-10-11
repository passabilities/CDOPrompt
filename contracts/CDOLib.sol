pragma solidity ^0.4.8;

import "./RedeemableTokenLib.sol";

library CDOLib {

  using RedeemableTokenLib for RedeemableTokenLib.Accounting;

  uint constant seniorSupply = 600000;
  uint constant mezzanineSupply = 400000;

  struct Tranche {
    RedeemableTokenLib.Accounting token;
  }

  struct CDO {
    address owner;
    bytes32[] loan_ids;
    Tranche seniorTranche;
    Tranche mezzanineTranche;
  }

  function initialize(CDO storage self) {
    self.owner = msg.sender;

    self.seniorTranche.token.totalSupply = seniorSupply;
    self.seniorTranche.token.balances[msg.sender] = seniorSupply;

    self.mezzanineTranche.token.totalSupply = mezzanineSupply;
    self.mezzanineTranche.token.balances[msg.sender] = mezzanineSupply;
  }

}
