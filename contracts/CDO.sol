pragma solidity ^0.4.8;

import "./CDOLib.sol";
import "./RedeemableTokenLib.sol";
import "./LoanRegistry.sol";

contract CDO {

  using SafeMath for uint;
  using CDOLib for CDOLib.CDO;

  event CDOCreated(
    bytes32 uuid,
    uint blockNumber
  );

  mapping (bytes32 => CDOLib.CDO) cdos;

  function CDO() {
  }

  function create(bytes32 uuid, bytes32[] loan_ids) {
    CDOLib.CDO cdo = cdos[uuid];

    cdo.initialize();
    cdo.loan_ids = loan_ids;

    CDOCreated(uuid, block.number);
  }

}
