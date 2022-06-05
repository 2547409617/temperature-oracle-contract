const TemperatureOracle = artifacts.require("Oracle/TemperatureOracle");


module.exports = function (deployer, network, accounts) {
  deployer.deploy(TemperatureOracle, accounts[0], 3, "-100.00", "100.00");
};
