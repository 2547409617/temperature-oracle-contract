// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";


import "./util/strings.sol";
import "./util/numbers.sol";
import "./util/RoleBasedAcl.sol";
import "./util/CustomEnumerableMap.sol";

import "./TemperatureOracleInterface.sol";

contract TemperatureOracle is RoleBasedAcl , TemperatureOracleInterface {
  using SafeCast for uint256;
  using SafeCast for int256;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  uint8 public constant defaultMinOracleNumber  = 3;
  int256 private constant scaleOfTemperature = 100;

  string private constant OWNER_ROLE = "OWNER_ROLE";
  string private constant ORACLE_ROLE = "ORACLE_ROLE";
  
  uint8 private numOracles = 0;
  uint8 private minOracleNumber = defaultMinOracleNumber;
  bool private oracleReady = false;
  // store computed temperature result
  string private temperature;
  // min temperature in cent format
  int256 private minTemperature;
  // max temperature in cent format
  int256 private maxTemperature;


  using CustomEnumerableMap for CustomEnumerableMap.AddressToInt256Map;
  // store oracle report temperature in cent int format
  CustomEnumerableMap.AddressToInt256Map  private temperatureMap;

  event DepolyContractEvent(address ownerAddress, uint8 minOracleNumber, string minTemperatureStr, string maxTemperatureStr);

  event AddOracleEvent(address oracleAddress, address ownerAddress);
  event RemoveOracleEvent(address oracleAddress);

  event GetTemperatureEvent(address callerAddress);
  event SetTemperatureEvent(string temperature, address callerAddress);

  /*
   * @param _minTemperatureStr, _maxTemperatureStr in float format string.
   */
  constructor(address _owner, uint8 _minOracleNumber, string memory _minTemperatureStr, string memory _maxTemperatureStr) {
    require (_minOracleNumber >= defaultMinOracleNumber, "minOracleNumber must greater or equal defaultMinOracleNumber!");
    
    minTemperature = numbers.floatstr2IntCent(_minTemperatureStr, scaleOfTemperature);
    maxTemperature = numbers.floatstr2IntCent(_maxTemperatureStr, scaleOfTemperature);

    require (maxTemperature > minTemperature, "maxTemperature must greater minTemperature");
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

  /*
   * oracle interface.
   * @return temperature in float format string.
   */
  function getTemperature() public returns (string memory) {
    if (!oracleReady) {
      revert ("Oracle not oracleReady!");
    }
    
    emit GetTemperatureEvent(msg.sender);
    return temperature;
  }

  /*
   * No event should not emited if the same oracle set the same temperature;
   * @param _temperatureStr temperature in float string format.
   */
  function SetTemperature(string memory _temperatureStr) public hasRole(ORACLE_ROLE) {
    int256 temp = numbers.floatstr2IntCent(_temperatureStr, scaleOfTemperature);
    require(temp >= minTemperature && temp <= maxTemperature, "Input temperature is out of range!");

    (bool exist, int256 value) = temperatureMap.tryGet(msg.sender);
    if (exist) {
      if (value == temp) {
        // no event emit
        return;
      }

      temperatureMap.remove(msg.sender);
      temperatureMap.set(msg.sender, temp);
    } else {
      temperatureMap.set(msg.sender, temp);
    }
    
    if (numOracles >= minOracleNumber && temperatureMap.length() >= minOracleNumber) {
      int256 middleTemperature = comupteTemperature();

      // convert temperature in cent number format to float number in string
      string memory sign = "";
      if (middleTemperature < 0) {
        middleTemperature = middleTemperature.mul(-1);
        sign = "-";
      }
      string memory part1 = numbers.postiveInt2str(middleTemperature / scaleOfTemperature);

      int256 cents = middleTemperature % scaleOfTemperature;
      string memory part2 = numbers.postiveInt2str(cents);
      string memory centsPadding = cents >= 10 ? "" : "0";
      temperature = string(bytes.concat(bytes(sign), bytes(part1), ".", bytes(centsPadding), bytes(part2)));
      oracleReady = true;
    }
    
    emit SetTemperatureEvent(_temperatureStr, msg.sender);
  }

  /*
   * find middle temperature to prevent bad data.
   */
  function comupteTemperature() private view returns (int256) {
    uint256 total = temperatureMap.length();
    int256[] memory temperatureArray = new int256[](total);

    for(uint256 i=0; i<total; i++) {
      (, int256 value) = temperatureMap.at(i);
      temperatureArray[i] = value;
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
