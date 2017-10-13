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
  TrancheLib.TrancheData[] trancheData;

  function CDO(address loanRegistryAddress) {
    loanRegistry = LoanRegistry(loanRegistryAddress);

    totalTrancheSupply = 1000000;
    trancheData = [
      TrancheLib.TrancheData(600000),
      TrancheLib.TrancheData(400000)
    ]
  }

  function create(bytes32 uuid, bytes32[] loan_ids) {
    CDOLib.CDO cdo = cdos[uuid];

    // Transfer all loan investors' tokens to CDO contract
    for(uint i = 0; i < loan_ids.length; i++) {
      bytes32 id = loan_id[i];

      for(uint j = 0; j < loanRegistry.getNubBids(id); j++) {
        var (bidder, amount, rate) = loanRegistry.getBidByIndex(j);
        loanRegistry.transferFrom(id, bidder, address(this), amount);
      }

    }
    cdo.initialize(loan_ids, trancheData);

    CDOCreated(uuid, block.number);
  }

  function getTotalWorth(bytes32 uuid) constant returns (uint) {
    CDOLib.CDO cdo = cdos[uuid];
    uint worth = 0;

    for(uint i = 0; i < cdo.loan_ids.length; i++) {
      bytes32 id = cdo.loan_ids[i];

      uint principal = loanRegistry.getPrincipal(id);
      uint rate = loanRegistry.getIntrestRate(id);

      worth = worth
        .add(principal)
        .add(principal.mul(rate));
    }

    return worth;
  }

  function getTrancheTotalWorthByIndex(bytes32 uuid, uint index) constant returns (uint) {
    return getTotalWorth(uuid).mul(cdos[uuid].tranches[index].token.totalSupply).div(totalTrancheSupply);
  }

  // Redeem investor's share for each tranche
  function redeemValue(bytes32 uuid) {
    CDOLib.CDO cdo = cdos[uuid];

    while(i++ < cdo.tranches.length) {
      cdo.tranches[i].token.redeemValue(uuid, msg.sender);
    }
  }

  // Withdraw repayment value from a loan and redeem investor's share
  function withdrawRepayment(bytes32 uuid, bytes32 loan_id) {
    CDOLib.CDO cdo = cdos[uuid];

    uint redeemable = loanRegistry.getRedeemableValue(loan_id, this);
    loanRegistry.redeemValue(loan_id, this);
    uint i = 0;
    while(i++ < cdo.tranches.length && redeemable > 0) {
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
    }

    redeemValue(uuid);
  }

  function getTrancheAmountRepaidByIndex(bytes32 uuid, uint index) returns (uint) {
    return cdos[uuid].tranches[index].getAmountRepaid();
  }

}
