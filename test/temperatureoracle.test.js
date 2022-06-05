const TemperatureOracle = artifacts.require("oracle/TemperatureOracle");

contract("TemperatureOracle", (accounts) => {
  it("SetTemperature data", async () => {
    const temperatureOracle = await TemperatureOracle.deployed();
    await temperatureOracle.addOracle(accounts[1], { from: accounts[0] });

    await temperatureOracle.SetTemperature("15.12", {from: accounts[1]});

    let hasExcption = false;
    try {
      await temperatureOracle.SetTemperature("15.120", {from: accounts[1]});
    } catch(error) {
       hasExcption = true;
    }

    assert.equal(
      hasExcption,
      true,
      "temperature with 3 decimal places should fail"
    );

    hasExcption = false;
    try {
      await temperatureOracle.SetTemperature("15.120.0", {from: accounts[1]});
    } catch(error) {
       hasExcption = true;
    }

    assert.equal(
      hasExcption,
      true,
      "temperature not float should fail"
    );

    hasExcption = false;
    try {
      await temperatureOracle.SetTemperature("15-120", {from: accounts[1]});
    } catch(error) {
       hasExcption = true;
    }

    assert.equal(
      hasExcption,
      true,
      "temperature not float should fail"
    );
  });

  it("GetTemperature ready", async () => {
    const temperatureOracle = await TemperatureOracle.deployed();
    await temperatureOracle.addOracle(accounts[1], { from: accounts[0] });
    
    await temperatureOracle.SetTemperature("15.12", {from: accounts[1]});

    let hasExcption = false;
    try {
      await temperatureOracle.getTemperature.call();
    } catch(error) {
       hasExcption = true;
    }

    assert.equal(
      hasExcption,
      true,
      "oracle should be not ready"
    );
    
  });

  it("SetTemperature positive data", async () => {
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

  it("SetTemperature nagetive data", async () => {
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

  it("SetTemperature positive and nagetive data", async () => {
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