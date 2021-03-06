import BigNumber from 'bignumber.js';

module.exports = {
  PERIOD_TYPE: {
    DAILY: 0,
    WEEKLY: 1,
    MONTHLY: 2,
    YEARLY: 3,
    FIXED: 4
  },

  LOAN_STATE: {
    NULL: 0,
    AUCTION: 1,
    REVIEW: 2,
    ACCEPTED: 3,
    REJECTED: 4
  },

  DEFAULT_TX_PARAMS: {
    gasPrice: new BigNumber(22000000000)
  }
}
