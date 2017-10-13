var VersionRegister = artifacts.require('./VersionRegister.sol')
var SafeMath = artifacts.require('./SafeMath.sol');
var RedeemableTokenLib = artifacts.require("./RedeemableTokenLib.sol");
var LoanLib = artifacts.require('./LoanLib.sol');
var LoanRegistry = artifacts.require("./LoanRegistry.sol");
var CDO = artifacts.require("./CDO.sol");
var CDOLib = artifacts.require("./CDOLib.sol");
var TrancheLib = artifacts.require("./TrancheLib.sol");
var Metadata = require("../package.json");
var semver = require('semver');

module.exports = function(deployer, network, accounts) {
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, RedeemableTokenLib);
  deployer.deploy(RedeemableTokenLib);
  deployer.link(SafeMath, LoanLib);
  deployer.link(RedeemableTokenLib, LoanLib);

  deployer.deploy(LoanLib);

  deployer.link(LoanLib, LoanRegistry);
  deployer.link(RedeemableTokenLib, LoanRegistry);

  deployer.deploy(CDOLib);
  deployer.deploy(TrancheLib);
  deployer.link(CDOLib, CDO);
  deployer.link(TrancheLib, CDO);
  deployer.link(RedeemableTokenLib, CDO);

  let versionRegister;
  const version = {
    major: semver.major(Metadata.version),
    minor: semver.minor(Metadata.version),
    patch: semver.patch(Metadata.version)
  }

  deployer.deploy(LoanRegistry)
    .then(() => {
      deployer.deploy(CDO, LoanRegistry.address)
    }).then(() => {
      return deployer.deploy(VersionRegister);
    }).then(() => {
      return VersionRegister.deployed();
    }).then((_versionRegister) => {
      versionRegister = _versionRegister;
      return versionRegister.updateCurrentVersion(version.major, version.minor, version.patch)
    }).then((result) => {
      return versionRegister.updateVersionMapping(version.major, version.minor, version.patch, LoanLib.address)
    });
};
