const TemperatureOracle = artifacts.require("oracle/TemperatureOracle");

contract("Oracle", (accounts) => {
  it("admin Oracle", async () => {
    const temperatureOracle = await TemperatureOracle.deployed();
    
    let hasExcption = false;
    try {
      await temperatureOracle.addOracle(accounts[1], { from: accounts[0] });
    } catch(error) {
       hasExcption = true;
    } finally {
    }

    assert.equal(
      hasExcption,
      false,
      "addOracle should success"
    );

    hasExcption = false;
    try {
      await temperatureOracle.addOracle(accounts[1], { from: accounts[0] });
    } catch(error) {
       hasExcption = true;
    } finally {
    }

    assert.equal(
      hasExcption,
      true,
      "The same addOracle repeatly should fail"
    );

     hasExcption = false;
    try {
      await temperatureOracle.addOracle(accounts[2], { from: accounts[0] });
      await temperatureOracle.addOracle(accounts[3], { from: accounts[0] });
    } catch(error) {
       hasExcption = true;
    } finally {
    }

    assert.equal(
      hasExcption,
      false,
      "addOracle again should success"
    );

    hasExcption = false;
    try {
      await temperatureOracle.removeOracle(accounts[1], { from: accounts[0] });
    } catch(error) {
       hasExcption = true;
    } finally {
    }

    assert.equal(
      hasExcption,
      true,
      "removeOracle should fail when no extra oracle"
    );

    await temperatureOracle.addOracle(accounts[4], { from: accounts[0] });
    hasExcption = false;
    try {
      
      await temperatureOracle.removeOracle(accounts[1], { from: accounts[0] });
    } catch(error) {
       hasExcption = true;
    } finally {
    }

    assert.equal(
      hasExcption,
      false,
      "removeOracle should success when has extra oracle"
    );
    
  });


});