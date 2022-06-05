// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "./util/strings.sol";
import "./util/numbers.sol";
import "./util/RoleBasedAcl.sol";

import "./TemperatureOracleInterface.sol";

contract TemperatureOracle is RoleBasedAcl , TemperatureOracleInterface {
  uint8 public constant defaultMinOracleNumber  = 3;
  int256 private constant scaleOfTemperature = 100;

  string private constant OWNER_ROLE = "OWNER_ROLE";
  string private constant ORACLE_ROLE = "ORACLE_ROLE";
  
  uint8 private numOracles = 0;
  uint8 private minOracleNumber = defaultMinOracleNumber;
  bool private ready = false;
  string private temperature;
  int256 private minTemperature;
  int256 private maxTemperature;

  using SafeCast for uint256;
  using SafeCast for int256;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  //using Numbers for *;
  
  
  using EnumerableMap for EnumerableMap.AddressToUintMap ;
  EnumerableMap.AddressToUintMap  private temperatureMap;

  event DepolyContractEvent(address ownerAddress, uint8 minOracleNumber, string minTemperatureStr, string maxTemperatureStr);

  event AddOracleEvent(address oracleAddress, address ownerAddress);
  event RemoveOracleEvent(address oracleAddress);

  event GetTemperatureEvent(address callerAddress);
  event SetTemperatureEvent(string temperature, address callerAddress);

  constructor(address _owner, uint8 _minOracleNumber, string memory _minTemperatureStr, string memory _maxTemperatureStr) {
    require (_minOracleNumber >= defaultMinOracleNumber, "minOracleNumber must greater or equal defaultMinOracleNumber!");
    
    minTemperature = numbers.floatstr2num(_minTemperatureStr, scaleOfTemperature);
    maxTemperature = numbers.floatstr2num(_maxTemperatureStr, scaleOfTemperature);

    string memory errMsg = string(bytes.concat(bytes("maxTemperature="), bytes(_maxTemperatureStr), bytes(" must greater minTemperature="), bytes(_minTemperatureStr)));
    require (maxTemperature > minTemperature, errMsg);
    minOracleNumber = _minOracleNumber;

    assignRole(OWNER_ROLE, msg.sender);
    emit DepolyContractEvent(_owner, _minOracleNumber, _minTemperatureStr, _maxTemperatureStr);
  }

  function addOracle (address _oracle) public hasRole(OWNER_ROLE) {
    require(!isAssignedRole(ORACLE_ROLE, _oracle), "Already an oracle!");
    assignRole(ORACLE_ROLE, _oracle);
    numOracles++;
    emit AddOracleEvent(_oracle, msg.sender);
  }

  function removeOracle(address _oracle) public hasRole(OWNER_ROLE) {
    require(isAssignedRole(ORACLE_ROLE, _oracle), "Not an oracle!");
    if (numOracles <= minOracleNumber) {
      revert("Oracle number will less than minOracleNumber!");
    }
    
    unassignRole(ORACLE_ROLE, _oracle);
    numOracles--;
    temperatureMap.remove(_oracle);
    emit RemoveOracleEvent(_oracle);
  }

  function getTemperature() public returns (string memory) {
    if (!ready) {
      revert ("Oracle not ready!");
    }
    
    emit GetTemperatureEvent(msg.sender);
    return temperature;
  }

  function SetTemperature(string memory _temperatureStr) public hasRole(ORACLE_ROLE) {
    int256 temp = numbers.floatstr2num(_temperatureStr, scaleOfTemperature);
    require(temp >= minTemperature && temp <= maxTemperature, "Input temperature is out of range!");
    temperatureMap.set(msg.sender, uint256(temp));
    if (numOracles >= minOracleNumber && temperatureMap.length() >= minOracleNumber) {
      int256 middleTemperature = comupteTemperature();
      string memory sign = "";
      if (middleTemperature < 0) {
        middleTemperature = middleTemperature.mul(-1);
        sign = "-";
      }
      string memory part1 = numbers.int2str(middleTemperature / scaleOfTemperature);

      int256 cents = middleTemperature % scaleOfTemperature;
      string memory part2 = numbers.int2str(cents);
      string memory centsPadding = cents >= 10 ? "" : "0";
      temperature = string(bytes.concat(bytes(sign), bytes(part1), ".", bytes(centsPadding), bytes(part2)));
      ready = true;
    }
    
    emit SetTemperatureEvent(_temperatureStr, msg.sender);
  }

  function comupteTemperature() private view returns (int256) {
    uint256 total = temperatureMap.length();
    int256[] memory temperatureArray = new int256[](total);

    for(uint256 i=0; i<total; i++) {
      (, uint256 value) = temperatureMap.at(i);
      temperatureArray[i] = int256(value);
    }

    numbers.quickSort(temperatureArray, 0, int(total-1));
    uint256 middle = total / 2;
    int256 middleTemperature = 0;
    if (middle * 2 == total) {
       middleTemperature = (temperatureArray[middle - 1] + temperatureArray[middle]) / 2;
    } else {
      middleTemperature = temperatureArray[middle];
    }
    return middleTemperature;
  }

}
