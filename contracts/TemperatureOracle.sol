// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./TemperatureOracleInterface.sol";

contract TemperatureOracle is AccessControl, TemperatureOracleInterface {
  uint public constant defaultMinOracleNumber  = 5;
  bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 private constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

  uint private numOracles = 0;
  uint private minOracleNumber = defaultMinOracleNumber;

  using EnumerableMap for EnumerableMap.AddressToUintMap;
  EnumerableMap.AddressToUintMap private temperatureMap;
  EnumerableMap.AddressToUintMap private updateTimeMap;

  event AddOracleEvent(address oracleAddress);
  event RemoveOracleEvent(address oracleAddress);

  event GetTemperatureEvent(address callerAddress);
  event SetTemperatureEvent(uint256 temperature, address callerAddress);

  constructor (address _owner, uint _minOracleNumber) {
    require (_minOracleNumber >= defaultMinOracleNumber, "minOracleNumber must greater or equal defaultMinOracleNumber!");
    minOracleNumber = _minOracleNumber;
    _setupRole(OWNER_ROLE, _owner);
  }

  function addOracle (address _oracle) public onlyRole(OWNER_ROLE) {
    require(!hasRole(ORACLE_ROLE, _oracle), "Already an oracle!");
    grantRole(ORACLE_ROLE, _oracle);
    numOracles++;
    emit AddOracleEvent(_oracle);
  }

  function removeOracle (address _oracle) public onlyRole(OWNER_ROLE) {
    require(hasRole(ORACLE_ROLE, _oracle), "Not an oracle!");
    require (numOracles > defaultMinOracleNumber, "Do not remove the last oracle!");
    revokeRole(ORACLE_ROLE, _oracle);
    numOracles--;
    emit RemoveOracleEvent(_oracle);
  }

  function getTemperature() public returns (uint256) {
    require (numOracles >= minOracleNumber, "numOracles must greater or equal minOracleNumber!");
    emit GetTemperatureEvent(msg.sender);
    return temperature;
  }

  function SetTemperature(uint256 _temperature) public onlyRole(ORACLE_ROLE) {
    temperatureMap.set(msg.sender, _temperature);
    updateTimeMap.set(msg.sender, now);
    emit SetTemperatureEvent(_temperature, _callerAddress);
  }

  function computeTemperature() private returns (uint256) {
    uint256 total = temperatureMap.length();
    require (total >= minOracleNumber, "Oracle not ready!");

    // find available temperatures
    uint[] memory temperatureArray = new uint[](total);
    uint[] memory staleOracleArray = new uint[](total);
    uint nowTime = now;
    for(uint i=0; i<total; i++){
      uint updateTime;
      address oracleAddress;
      (oracleAddress, updateTime) = updateTimeMap.at(i);
      if (nowTime < updateTime + 10 minutes) {
        uint temperature = temperatureMap.get(oracleAddress);
        temperatureArray.push(temperature);
        result=result+i;
      } else {
        staleOracleArray.push(oracleAddress);
      }
     }

     revert (temperatureArray.length() >= minOracleNumber, "Too many oracle not work!");

    // remove stale oracle temperature
     for (uint i=0; i<staleOracleArray.length; i++) {
        temperatureMap.remove(staleOracleArray[i]);
        updateTimeMap.remove(staleOracleArray[i]);
     }

  }




}
