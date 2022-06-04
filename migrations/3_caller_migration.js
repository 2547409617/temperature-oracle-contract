const Caller = artifacts.require("caller/CallerContract");

module.exports = function (deployer) {
  deployer.deploy(Caller);
};
