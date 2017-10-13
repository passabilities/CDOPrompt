pragma solidity ^0.4.8;

import "./CDOLib.sol";
import "./TrancheLib.sol";
import "./RedeemableTokenLib.sol";
import "./LoanRegistry.sol";

contract CDO {

  using SafeMath for uint;
  using RedeemableTokenLib for RedeemableTokenLib.Accounting;
  using CDOLib for CDOLib.CDO;
  using TrancheLib for TrancheLib.Tranche;

  event CDOCreated(
    bytes32 uuid,
    uint blockNumber
  );

  mapping (bytes32 => CDOLib.CDO) cdos;
  LoanRegistry loanRegistry;
  uint totalTrancheSupply;
  uint[] trancheSupply;

  function CDO(address loanRegistryAddress) {
    loanRegistry = LoanRegistry(loanRegistryAddress);

    totalTrancheSupply = 1000000;
    trancheSupply = [ 600000, 400000 ];
  }

  function create(bytes32 uuid, bytes32[] loan_ids) {
    uint i;
    uint j;
    CDOLib.CDO cdo = cdos[uuid];
    cdo.loan_ids = loan_ids;

    // Initialize each tranche
    cdo.tranches.length = trancheSupply.length;
    for(i = 0; i < trancheSupply.length; i++) {
      uint supply = trancheSupply[i];
      cdo.tranches[i].token.totalSupply = supply;
      cdo.tranches[i].token.balances[msg.sender] = supply;

      cdo.tranches[i].interestRate = 0;
    }

    CDOCreated(uuid, block.number);
  }

  function getTotalWorth(bytes32 uuid) constant returns (uint) {
    CDOLib.CDO cdo = cdos[uuid];
    uint worth = 0;

    for(uint i = 0; i < cdo.loan_ids.length; i++) {
      bytes32 id = cdo.loan_ids[i];

      uint principal = loanRegistry.getPrincipal(id);
      uint rate = loanRegistry.getInterestRate(id);

      worth = worth
        .add(principal)
        // Interest rate in Wei
        .add(principal.mul(rate).div(1 ether));
    }

    return worth;
  }

  function getTrancheTotalWorthByIndex(bytes32 uuid, uint index) constant returns (uint) {
    return getTotalWorth(uuid).mul(cdos[uuid].tranches[index].token.totalSupply).div(totalTrancheSupply);
  }

  function redeemTrancheValueByIndex(bytes32 uuid, uint index) {
    cdos[uuid].tranches[index].token.redeemValue(uuid, msg.sender);
  }

  // Withdraw repayment value from a loan
  function withdrawRepayment(bytes32 uuid, bytes32 loan_id) {
    CDOLib.CDO cdo = cdos[uuid];

    uint redeemable = loanRegistry.getRedeemableValue(loan_id, this);
    loanRegistry.redeemValue(loan_id, this);
    uint i = 0;
    while(i < cdo.tranches.length && redeemable > 0) {
      uint amountLeft = getTrancheTotalWorthByIndex(uuid, i) - cdo.tranches[i].getAmountRepaid();
      // Go to next tranche if already paid in full
      if(amountLeft == 0) continue;

      if(redeemable > amountLeft) {
        cdo.tranches[i].repay(amountLeft);
        redeemable = redeemable.sub(amountLeft);
      } else {
        cdo.tranches[i].repay(redeemable);
        redeemable = 0;
      }

      i++;
    }
  }

  function getTrancheAmountRepaidByIndex(bytes32 uuid, uint index) returns (uint) {
    return cdos[uuid].tranches[index].getAmountRepaid();
  }

}
