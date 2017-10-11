module.exports = {
  CDOCreated(params) {
    return {
      event: 'CDOCreated',
      args: {
        uuid: params.uuid,
        blockNumber: params.blockNumber
      }
    }
  }
}
