// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/kUSDToken.sol";

contract MockKUSDToken is kUSDToken {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        address minter_,
        address burner_,
        uint32 localEid_,
        address endpoint_
    ) kUSDToken(name_, symbol_, owner_, minter_, burner_, localEid_, endpoint_) {}
    
    function mockSetBalance(address account, uint256 amount) external {
        _mint(account, amount);
    }
    
    function mockBurn(address account, uint256 amount) external {
        _burn(account, amount);
    }
} 