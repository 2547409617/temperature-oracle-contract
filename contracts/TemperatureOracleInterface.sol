// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.8.14;

interface TemperatureOracleInterface {
  function getTemperature() external returns (string memory);
}