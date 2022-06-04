// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "./util/strings.sol";

import "./TemperatureOracleInterface.sol";

contract TemperatureOracle is AccessControl, TemperatureOracleInterface {
  uint8 public constant defaultMinOracleNumber  = 3;
  int256 private constant scaleOfTemperature = 100;

  bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 private constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

  
  uint8 private numOracles = 0;
  uint8 private minOracleNumber = defaultMinOracleNumber;
  bool private ready = false;
  int256 private temperature;
  int256 private minTemperature;
  int256 private maxTemperature;

  using SafeCast for uint256;
  using SignedSafeMath for int256;
  using SafeMath for uint256;
  using strings for *;

  using EnumerableMap for EnumerableMap.Bytes32ToBytes32Map;
  EnumerableMap.Bytes32ToBytes32Map private temperatureMap;

  event AddOracleEvent(address oracleAddress);
  event RemoveOracleEvent(address oracleAddress);

  event GetTemperatureEvent(address callerAddress);
  event SetTemperatureEvent(string temperature, address callerAddress);

  constructor (address _owner, uint8 _minOracleNumber, string memory _minTemperatureStr, string memory _maxTemperatureStr) {
    require (_minOracleNumber >= defaultMinOracleNumber, "minOracleNumber must greater or equal defaultMinOracleNumber!");
    
    minTemperature = floatstr2num(_minTemperatureStr);
    maxTemperature = floatstr2num(_maxTemperatureStr);

    string memory errMsg = string(bytes.concat(bytes("maxTemperature="), bytes(_maxTemperatureStr), bytes(" must greater minTemperature="), bytes(_minTemperatureStr)));
    require (maxTemperature > minTemperature, errMsg);
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
    if (numOracles <= minOracleNumber) {
      revert("Oracle number will less than minOracleNumber!");
    }
    
    revokeRole(ORACLE_ROLE, _oracle);
    numOracles--;
    temperatureMap.remove(bytes32(uint256(uint160(_oracle))));
    emit RemoveOracleEvent(_oracle);
  }

  function getTemperature() public returns (string memory) {
    if (!ready) {
      revert ("Oracle not ready!");
    }
    
    string memory part1 = int2str(temperature / scaleOfTemperature);
    string memory part2 = int2str(temperature % scaleOfTemperature);
    string memory _temperatureStr = string(bytes.concat(bytes(part1), ".", bytes(part2)));
    emit GetTemperatureEvent(msg.sender);
    return _temperatureStr;
  }

  function SetTemperature(string memory _temperatureStr) public onlyRole(ORACLE_ROLE) {
    int256 _temperature = floatstr2num(_temperatureStr);
    require(_temperature >= minTemperature && _temperature <= maxTemperature, "Input temperature is out of range!");
    temperatureMap.set(bytes32(uint256(uint160(msg.sender))), temperatureToBytes32(_temperature));
    if (numOracles >= minOracleNumber) {
      temperature = comupteTemperature();
      ready = true;
    }
    
    emit SetTemperatureEvent(_temperatureStr, msg.sender);
  }

  function comupteTemperature() private returns (int256) {
    uint256 total = temperatureMap.length();
    int256[] memory temperatureArray = new int256[](total);
    for(uint256 i=0; i<total; i++) {
      (, bytes32 value) = temperatureMap.at(i);
      string memory strValue = bytes32ToStr(value);
      temperatureArray[i] = str2num(strValue);
    }

    quickSort(temperatureArray, 0, int(total-1));
    uint256 middle = total / 2;
    int256 middleTemperature;
    if (middle * 2 == total) {
      middleTemperature = (temperatureArray[middle - 1] + temperatureArray[middle]) / 2;
    } else {
      middleTemperature = temperatureArray[middle];
    }
    return middleTemperature;
  }

  function floatstr2num(string memory floatStr) public pure returns(int256) {
    int256 sign = 1;
    strings.slice memory slice = floatStr.toSlice();
    if (slice.startsWith("-".toSlice())) {
      sign = -1;
      slice.beyond("-".toSlice());
    }

    strings.slice memory delimeterSlice = ".".toSlice();
    uint count = slice.count(delimeterSlice);
    require(count < 2, "Input not an float!");

    int256 number = 0;
    for(uint i = 0; i < count + 1; i++) {
        string memory part = slice.split(delimeterSlice).toString();
        if (i == 0) {
          number = str2num(part);
          number.mul(scaleOfTemperature);
          require(slice.len() <= 1 + 2, "Input float must up to 2 decimal places!");
        } else {
          number.add(str2num(part));
        }
    }
    return number.mul(sign);
  }

// https://stackoverflow.com/questions/68976364/solidity-converting-number-strings-to-numbers
  function str2num(string memory numString) public pure returns(int256) {
      uint256  val = 0;
      bytes   memory stringBytes = bytes(numString);
      for (uint256  i=0; i<stringBytes.length; i++) {
          uint256 exp = stringBytes.length - i;
          bytes1 b = stringBytes[i];
          require(b >= "0" && b <= "9", "Input not an float!");
          uint8 n = uint8(b) - uint8(0x30);
          uint256 number = uint256(n);
          uint16 ratio = (10**(exp-1)).toUint16();
 
          val +=  number.mul(ratio); 
      }
    return val.toInt256();
  }

  function int2str(int256 number) public pure returns(string memory) {
    bool sign = number >= 0;
    if (!sign) {
      number.mul(-1);
    }

    string memory numString = Strings.toString(uint256(number));
    if (!sign) {
      numString = string(bytes.concat("-", bytes(numString)));
    }
    return numString;
  }

  function temperatureToBytes32(int256 _temperature) private pure returns (bytes32 result) {
    string memory source = int2str(_temperature);
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
  }

  function bytes32ToStr(bytes32 _bytes32) public pure returns (string memory) {
    bytes memory bytesArray = new bytes(32);
    for (uint256 i; i < 32; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

   function quickSort(int256[] memory arr, int left, int right) internal pure {
    int i = left;
    int j = right;
    if (i == j) {
      return;
    }
    
    int256 pivot = arr[uint(left + (right - left) / 2)];
    while (i <= j) {
        while (arr[uint(i)] > pivot) {
          i++;
        }
        while (pivot > arr[uint(j)]) {
          j--;
        }
        if (i <= j) {
            (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
            i++;
            j--;
        }
    }

    if (left < j) {
      quickSort(arr, left, j);
    }
        
    if (i < right) {
      quickSort(arr, i, right);
    }
  }

}
