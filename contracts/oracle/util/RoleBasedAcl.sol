// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract RoleBasedAcl {
  mapping(address => mapping(string => bool)) roles;

  
  function assignRole (string memory role, address entity) public {
    roles[entity][role] = true;
  }
  
  function unassignRole (string memory role, address entity) public {
    roles[entity][role] = false;
  }
  
  function isAssignedRole (string memory role, address entity) public view returns (bool) {
    return roles[entity][role];
  }
  
  modifier hasRole (string memory role)  {
    if (!roles[msg.sender][role] ) {
      revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(msg.sender), 20),
                        " is missing role ",
                        role
                    )
                )
            );
    }
    _;
  }
}