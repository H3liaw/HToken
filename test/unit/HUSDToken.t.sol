// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../base/BaseHTest.t.sol";
import "../../src/HUSDToken.sol";

contract HUSDTokenTest is BaseHTest {
    HUSDToken public token;
    
    function setUp() public override {
        super.setUp();
        token = new kUSDToken("kUSD Token", "kUSD", admin, admin, admin, 1, address(0));
    }
    
    function test_InitialState() public {
        assertEq(token.name(), "kUSD Token");
        assertEq(token.symbol(), "kUSD");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
    }
    
    function test_Mint() public {
        uint256 amount = 1000 * 10**18;
        token.mint(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), amount);
    }
    
    function test_Burn() public {
        uint256 amount = 1000 * 10**18;
        token.mint(user1, amount);

        token.grantBurnerRole(user1);
        
        vm.stopPrank();
        vm.startPrank(user1);
        token.burn(user1,amount);
        
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.totalSupply(), 0);
    }
    
    function test_Transfer() public {
        uint256 amount = 1000 * 10**18;
        token.mint(user1, amount);
        
        vm.stopPrank();
        vm.startPrank(user1);
        token.transfer(user2, amount);
        
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(user2), amount);
    }
} 