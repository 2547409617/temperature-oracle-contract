// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

import "./strings.sol";

library numbers {

  using strings for *;

  using SafeCast for uint256;
  using SafeCast for int256;
  using SafeMath for uint256;
  using SignedSafeMath for int256;
  
  function floatstr2num(string memory floatStr, int256 scaleOfTemperature) public pure returns(int256) {
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