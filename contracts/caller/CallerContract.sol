// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../oracle/TemperatureOracleInterface.sol";

contract CallerContract is Ownable {
  TemperatureOracleInterface private oracleInstance;
  address private oracleAddress;

  function setOracleInstanceAddress (address _oracleInstanceAddress) public onlyOwner {
    oracleAddress = _oracleInstanceAddress;
    oracleInstance = TemperatureOracleInterface(oracleAddress);
  }

  function queryTemperature() public returns (string memory) {
    return oracleInstance.getTemperature();
  }
}