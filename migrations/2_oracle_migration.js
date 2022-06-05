const TemperatureOracle = artifacts.require("Oracle/TemperatureOracle");
const numbers = artifacts.require("Oracle/util/numbers");
const strings = artifacts.require("Oracle/util/strings");


module.exports = function (deployer, network, accounts) {
  deployer.deploy(numbers);
  deployer.link(numbers, [TemperatureOracle]);

  deployer.deploy(strings);
  deployer.link(strings, [TemperatureOracle]);

  deployer.deploy(TemperatureOracle, accounts[0], 3, "-100.00", "100.00");
};
