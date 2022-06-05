// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "./util/strings.sol";
import "./util/RoleBasedAcl.sol";

import "./TemperatureOracleInterface.sol";

contract TemperatureOracle is RoleBasedAcl , TemperatureOracleInterface {
//contract TemperatureOracle is  TemperatureOracleInterface {
  uint8 public constant defaultMinOracleNumber  = 3;
  int256 private constant scaleOfTemperature = 100;

  //bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
  //bytes32 private constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
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
  
  using strings for *;

  using EnumerableMap for EnumerableMap.AddressToUintMap ;
  EnumerableMap.AddressToUintMap  private temperatureMap;

  event DepolyContractEvent(address ownerAddress, uint8 minOracleNumber, string minTemperatureStr, string maxTemperatureStr);

  event AddOracleEvent(address oracleAddress, address ownerAddress);
  event RemoveOracleEvent(address oracleAddress);

  event GetTemperatureEvent(address callerAddress);
  event SetTemperatureEvent(string temperature, address callerAddress);

  constructor(address _owner, uint8 _minOracleNumber, string memory _minTemperatureStr, string memory _maxTemperatureStr) {
    require (_minOracleNumber >= defaultMinOracleNumber, "minOracleNumber must greater or equal defaultMinOracleNumber!");
    
    minTemperature = floatstr2num(_minTemperatureStr);
    maxTemperature = floatstr2num(_maxTemperatureStr);

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
    //require(owner == msg.sender, "Caller is not a OWNER_ROLE");
    require(isAssignedRole(ORACLE_ROLE, _oracle), "Not an oracle!");
    if (numOracles <= minOracleNumber) {
      revert("Oracle number will less than minOracleNumber!");
    }
    
    unassignRole(ORACLE_ROLE, _oracle);
    numOracles--;
    temperatureMap.remove(_oracle);
    emit RemoveOracleEvent(_oracle);
  }

  function getRoleValueStr() public pure returns (string memory) {
    return toHex(keccak256("OWNER_ROLE"));
  }

  function getTemperature() public returns (string memory) {
    if (!ready) {
      revert ("Oracle not ready!");
    }
    
    emit GetTemperatureEvent(msg.sender);
    return temperature;
  }

  function SetTemperature(string memory _temperatureStr) public hasRole(ORACLE_ROLE) {
    //require(hasRole(ORACLE_ROLE, msg.sender), "Caller is not a ORACLE_ROLE");
    int256 temp = floatstr2num(_temperatureStr);
    require(temp >= minTemperature && temp <= maxTemperature, "Input temperature is out of range!");
    temperatureMap.set(msg.sender, uint256(temp));
    if (numOracles >= minOracleNumber && temperatureMap.length() >= minOracleNumber) {
      int256 middleTemperature = comupteTemperature();
      string memory sign = "";
      if (middleTemperature < 0) {
        middleTemperature = middleTemperature.mul(-1);
        sign = "-";
      }
      string memory part1 = int2str(middleTemperature / scaleOfTemperature);

      int256 cents = middleTemperature % scaleOfTemperature;
      string memory part2 = int2str(cents);
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

    quickSort(temperatureArray, 0, int(total-1));
    uint256 middle = total / 2;
    int256 middleTemperature = 0;
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
          number = number.mul(scaleOfTemperature);
        } else {
          int256 temp = str2num(part);
          string memory errMsg = string(bytes.concat(bytes("Input float must up to 2 decimal places, ["), bytes(Strings.toString(temp.toUint256())), bytes("]")));
          require(temp < 100, errMsg);
          number = number.add(temp);
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
    return Strings.toString(uint256(number));
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

  function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
    result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
          (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
    result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
          (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
    result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
          (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
    result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
          (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
    result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
          (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
    result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
           uint256 (result) +
           (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
           0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);
}

function toHex (bytes32 data) public pure returns (string memory) {
    return string (abi.encodePacked ("0x", toHex16 (bytes16 (data)), toHex16 (bytes16 (data << 128))));
}

}
