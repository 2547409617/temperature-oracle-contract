const TemperatureOracle = artifacts.require("oracle/TemperatureOracle");

contract("Temperature", (accounts) => {
  let temperatureOracle;

   before("TemperatureOracle before", async () => {
    temperatureOracle = await TemperatureOracle.deployed();
    await temperatureOracle.addOracle(accounts[1], { from: accounts[0] });
    await temperatureOracle.addOracle(accounts[2], { from: accounts[0] });
    await temperatureOracle.addOracle(accounts[3], { from: accounts[0] });
    });

  it("SetTemperature data", async () => {
    before("SetTemperature data before", async () => {
    });

    after("SetTemperature data after", async () => {
    });
   
    await temperatureOracle.SetTemperature("15.11", {from: accounts[1]});

    let hasExcption = false;
    try {
      await temperatureOracle.SetTemperature("15.110", {from: accounts[1]});
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
    await temperatureOracle.SetTemperature("15.15", {from: accounts[1]});
    await temperatureOracle.SetTemperature("26.05", {from: accounts[2]});
    await temperatureOracle.SetTemperature("4.95", {from: accounts[3]});

    let outputTemperature = await temperatureOracle.getTemperature.call();
    assert.equal(
      outputTemperature,
      "15.15",
      "temperature not correctly"
    );
  });

  it("SetTemperature nagetive data", async () => {
    await temperatureOracle.SetTemperature("-15.06", {from: accounts[1]});
    await temperatureOracle.SetTemperature("-26.06", {from: accounts[2]});
    await temperatureOracle.SetTemperature("-4.46", {from: accounts[3]});

    let outputTemperature = await temperatureOracle.getTemperature.call();
    assert.equal(
      outputTemperature,
      "-15.06",
      "temperature not correctly"
    );

  });

  it("SetTemperature positive and nagetive data", async () => {
    await temperatureOracle.SetTemperature("15.17", {from: accounts[1]});
    await temperatureOracle.SetTemperature("-26.07", {from: accounts[2]});
    await temperatureOracle.SetTemperature("4.97", {from: accounts[3]});

    let outputTemperature = await temperatureOracle.getTemperature.call();
    assert.equal(
      outputTemperature,
      "4.97",
      "temperature not correctly"
    );

  });
});