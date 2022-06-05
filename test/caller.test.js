const CallerContract = artifacts.require("caller/CallerContract");
const TemperatureOracle = artifacts.require("oracle/TemperatureOracle");


contract("CallerContract", (accounts) => {
  it("queryTemperature", async () => {
    const callerContract = await CallerContract.deployed();
    const temperatureOracle = await TemperatureOracle.deployed();
    callerContract.setOracleInstanceAddress(temperatureOracle.address);

    await temperatureOracle.addOracle(accounts[1], { from: accounts[0] });
    await temperatureOracle.addOracle(accounts[2], { from: accounts[0] });
    await temperatureOracle.addOracle(accounts[3], { from: accounts[0] });

   
    await temperatureOracle.SetTemperature("-15.02", {from: accounts[1]});
    await temperatureOracle.SetTemperature("-26.03", {from: accounts[2]});
    await temperatureOracle.SetTemperature("-4.98", {from: accounts[3]});

    let oracleTemperature = await temperatureOracle.getTemperature.call();
    assert.equal(
      oracleTemperature,
      "-15.02",
      "temperature not correctly"
    );
    
    let hasExcption = false;
    var outputTemperature;
    try {
       outputTemperature = await callerContract.queryTemperature.call();
    } catch(error) {
       hasExcption = true;
    }

    assert.equal(
      hasExcption,
      false,
      "queryTemperature should success"
    );

    assert.equal(
      outputTemperature,
      "-15.02",
      "temperature not correctly"
    );
  });
});