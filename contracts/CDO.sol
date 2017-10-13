pragma solidity ^0.4.8;

import "./CDOLib.sol";
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

  function CDO(address loanRegistryAddress) {
    loanRegistry = LoanRegistry(loanRegistryAddress);
  }

  function create(bytes32 uuid, bytes32[] loan_ids) {
    CDOLib.CDO cdo = cdos[uuid];

    // Determine CDO total worth
    //   * total worth = loan principals + loan rates
    uint totalWorth = 0;
    for(uint i = 0; i < loan_ids.length; i++) {
      uint principal = loanRegistry.getPrincipal(loan_ids[i]);
      uint rate = loanRegistry.getIntrestRate(loan_ids[i]);

      totalWorth = totalWorth
        .add(principal)
        .add(principal.mul(rate));
    }
    cdo.initialize(totalWorth, loan_ids);

    CDOCreated(uuid, block.number);
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

  function getTotalWorth(bytes32 uuid) constant returns (uint) {
    return cdos[uuid].totalWorth;
  }

  function getSeniorAmountRepaid(bytes32 uuid) returns (uint) {
    return cdos[uuid].seniorTranche.token.totalValueAccrued;
  }

  function getMezzanineAmountRepaid(bytes32 uuid) returns (uint) {
    return cdos[uuid].mezzanineTranche.token.totalValueAccrued;
  }

}
