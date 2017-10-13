pragma solidity ^0.4.8;

import "./CDOLib.sol";
import "./TrancheLib.sol";
import "./RedeemableTokenLib.sol";
import "./LoanRegistry.sol";

contract CDO {

  using SafeMath for uint;
  using RedeemableTokenLib for RedeemableTokenLib.Accounting;
  using CDOLib for CDOLib.CDO;

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

  function repayment(bytes32 uuid) payable {
    CDOLib.CDO cdo = cdos[uuid];

    uint amountLeft = cdo.seniorTranche.totalWorth - cdo.seniorTranche.token.totalValueAccrued;

    // Payout the senior tranche in full first.
    if(amountLeft > 0) {
      // If sent value goes over senior total worth, pay rest to mezzanine.
      // Otherwise, pay full amount to senior.
      if(msg.value > amountLeft) {
        paySeniorTranche(cdo, amountLeft);
        payMezzanineTranche(cdo, msg.value - amountLeft);
      } else {
        paySeniorTranche(cdo, msg.value);
      }
    } else {
      payMezzanineTranche(cdo, msg.value);
    }
  }

  function paySeniorTranche(CDOLib.CDO cdo, uint amount) internal {
    cdo.seniorTranche.token.totalValueAccrued =
      cdo.seniorTranche.token.totalValueAccrued.add(amount);
  }

  function payMezzanineTranche(CDOLib.CDO cdo, uint amount) internal {
    cdo.seniorTranche.token.totalValueAccrued =
      cdo.seniorTranche.token.totalValueAccrued.add(amount);
  }

  function redeemInvestment(bytes32 uuid) {
    cdos[uuid].seniorTranche.token.redeemValue(uuid, msg.sender);
    cdos[uuid].mezzanineTranche.token.redeemValue(uuid, msg.sender);
  }

  function getSeniorAmountRepaid(bytes32 uuid) returns (uint) {
    return cdos[uuid].seniorTranche.token.totalValueAccrued;
  }

  function getMezzanineAmountRepaid(bytes32 uuid) returns (uint) {
    return cdos[uuid].mezzanineTranche.token.totalValueAccrued;
  }

}
