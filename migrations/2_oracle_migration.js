const TemperatureOracle = artifacts.require("TemperatureOracle");


module.exports = function (deployer) {
  deployer.deploy(TemperatureOracle, "0xe646DF84ed2d88933058AD01BD8280390ae08534", 3, "-100.00", "100.00");
};
