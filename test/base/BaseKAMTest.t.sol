// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/kUSDToken.sol";

contract BaseKAMTest is Test {
    address public admin;
    address public user1;
    address public user2;
    
    function setUp() public virtual {
        admin = makeAddr("admin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        vm.startPrank(admin);
    }
    
    function tearDown() public virtual {
        vm.stopPrank();
    }
} 