// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface TemperatureOracleInterface {
  /*
   * oracle interface.
   * @return temperature in float format string.
   */
  function getTemperature() external returns (string memory);
}