pragma solidity ^0.4.8;


/**
 * @title TimeLocked
 * @dev The TimeLocked contract encapsulates basic modifiers for any contract
 *    with time locked functionality.
 *    Note: block timestamps are by no means accurate in ethereum, but have
 *      an accepted margin error of 900 seconds, so timelocks should not be
 *      specified with an expectation of subhourly accuracy.
 */
contract TimeLocked {
   uint public timeLock;

   function TimeLocked(uint _timeLock) {
     timeLock = _timeLock;
   }

   modifier beforeTimeLock() {
     if (block.timestamp > timeLock) {
       throw;
     }
     _;
   }

   modifier afterTimeLock() {
     if (block.timestamp <= timeLock) {
       throw;
     }
     _;
   }
}
