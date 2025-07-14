// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/HUSDToken.sol";

contract BaseHForkTest is Test {
    // Common test variables
    address public admin;
    address public user1;
    address public user2;
    
    // Chain configuration
    string[] public CHAINS = ["BASE"];
    uint256[] public FORK_BLOCKS = [29_532_162]; // Latest block number for BASE
    
    // Token addresses on BASE
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant WBTC = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
    
    // Chainlink price feed addresses on BASE
    address constant ETH_USD_FEED = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
    address constant BTC_USD_FEED = 0xCCADC697c55bbB68dc5bCdf8d3CBe83CdD4E071E;
    
    // Heartbeat values
    uint256 constant ETH_HEARTBEAT = 1200; // 20 minutes
    uint256 constant BTC_HEARTBEAT = 1200; // 20 minutes
    
    function _createFork(string memory chain, uint256 forkBlock) internal returns (uint256) {
        string memory rpc = vm.envString(string.concat(chain, "_RPC_URL"));
        uint256 fork = vm.createSelectFork(rpc);
        vm.rollFork(forkBlock);
        return fork;
    }
    
    function _setUp(string[] memory chains, uint256[] memory forkBlocks) internal virtual {
        require(chains.length == forkBlocks.length, "chains and blocks length mismatch");
        
        // Create forks for each chain
        for (uint256 i = 0; i < chains.length; i++) {
            _createFork(chains[i], forkBlocks[i]);
        }
        
        // Setup test accounts
        admin = makeAddr("admin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Fund test accounts
        vm.deal(admin, 1000 ether);
        vm.deal(user1, 1000 ether);
        vm.deal(user2, 1000 ether);
        
        // Set msg.sender as admin for all tests
        vm.startPrank(admin);
    }
    
    // Common teardown function
    function tearDown() public virtual {
        vm.stopPrank();
    }
} 