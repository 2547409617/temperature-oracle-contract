const TemperatureOracle = artifacts.require("oracle/TemperatureOracle");
const Caller = artifacts.require("caller/CallerContract");


contract("TemperatureOracle", (accounts) => {
  it("addOracle and SetTemperature positive data", async () => {
    const temperatureOracle = await TemperatureOracle.deployed();
    await temperatureOracle.addOracle(accounts[1], { from: accounts[0] });
    await temperatureOracle.addOracle(accounts[2], { from: accounts[0] });
    await temperatureOracle.addOracle(accounts[3], { from: accounts[0] });

    await temperatureOracle.SetTemperature("15.12", {from: accounts[1]});
    await temperatureOracle.SetTemperature("26.03", {from: accounts[2]});
    await temperatureOracle.SetTemperature("4.98", {from: accounts[3]});

    let outputTemperature = await temperatureOracle.getTemperature.call();
    assert.equal(
      outputTemperature,
      "15.12",
      "temperature not correctly"
    );
  });

  it("addOracle and SetTemperature nagetive data", async () => {
    const temperatureOracle = await TemperatureOracle.deployed();
    await temperatureOracle.addOracle(accounts[1], { from: accounts[0] });
    await temperatureOracle.addOracle(accounts[2], { from: accounts[0] });
    await temperatureOracle.addOracle(accounts[3], { from: accounts[0] });

   
    await temperatureOracle.SetTemperature("-15.02", {from: accounts[1]});
    await temperatureOracle.SetTemperature("-26.03", {from: accounts[2]});
    await temperatureOracle.SetTemperature("-4.98", {from: accounts[3]});

    let outputTemperature = await temperatureOracle.getTemperature.call();
    assert.equal(
      outputTemperature,
      "-15.02",
      "temperature not correctly"
    );

  });

  it("addOracle and SetTemperature positive and nagetive data", async () => {
    const temperatureOracle = await TemperatureOracle.deployed();
    await temperatureOracle.addOracle(accounts[1], { from: accounts[0] });
    await temperatureOracle.addOracle(accounts[2], { from: accounts[0] });
    await temperatureOracle.addOracle(accounts[3], { from: accounts[0] });

    await temperatureOracle.SetTemperature("15.12", {from: accounts[1]});
    await temperatureOracle.SetTemperature("-26.03", {from: accounts[2]});
    await temperatureOracle.SetTemperature("4.98", {from: accounts[3]});

    let outputTemperature = await temperatureOracle.getTemperature.call();
    assert.equal(
      outputTemperature,
      "4.98",
      "temperature not correctly"
    );

  });
});