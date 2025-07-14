// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../base/BaseHForkTest.t.sol";
import "../../src/HUSDToken.sol";

contract HUSDTokenForkTest is BaseHForkTest {
    HUSDToken public token;
    
    function setUp() public {
        _setUp(CHAINS, FORK_BLOCKS);
        
        token = new kUSDToken("kUSD Token", "kUSD", admin, admin, admin, 1, address(0));
    }
    
    function test_InitialState() public {
        assertEq(token.name(), "kUSD Token");
        assertEq(token.symbol(), "kUSD");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
    }
    
    function test_Mint() public {
        token.grantMinterRole(user1);
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
    
    function test_TransferFrom() public {
        uint256 amount = 1000 * 10**18;
        token.mint(user1, amount);
        
        vm.stopPrank();
        vm.startPrank(user1);
        token.approve(user2, amount);
        
        vm.stopPrank();
        vm.startPrank(user2);
        token.transferFrom(user1, user2, amount);
        
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(user2), amount);
    }
    
    function test_Allowance() public {
        uint256 amount = 1000 * 10**18;
        token.mint(user1, amount);
        
        vm.stopPrank();
        vm.startPrank(user1);
        token.approve(user2, amount);
        
        assertEq(token.allowance(user1, user2), amount);
    }
} 