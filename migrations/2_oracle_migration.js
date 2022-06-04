const Oracle = artifacts.require("TemperatureOracle");


module.exports = function (deployer) {
  deployer.deploy(Oracle, 3, -100.00, 100.00);
};
