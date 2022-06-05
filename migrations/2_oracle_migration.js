const TemperatureOracle = artifacts.require("Oracle/TemperatureOracle");


module.exports = function (deployer) {
  deployer.deploy(TemperatureOracle, '0x4B76E22D805845052D48936Dd515f22FCf600E01', 3, "-100.00", "100.00");
};
