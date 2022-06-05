// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface TemperatureOracleInterface {
  function getTemperature() external returns (string memory);
}