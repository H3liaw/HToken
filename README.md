# kUSD Protocol

[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.23-blue)](https://docs.soliditylang.org/)

> **Multi-Collateral Yield-Bearing Stablecoin Protocol**

HUSD is a sophisticated stablecoin protocol that combines institutional-grade asset management with public yield opportunities through a multi-collateral approach.

## 🎯 Overview

**Core Value Proposition:**
- **For Institutions:** Direct hUSD minting with any supported collateral + professional asset management
- **For Public Users:** Yield-bearing stablecoin staking with ERC4626 compatibility  
- **For Protocol:** Sustainable revenue from trading profits and DeFi yields across multiple assets

## 🏗️ Architecture

### Smart Contracts

```
┌─────────────────┐    ┌──────────────────┐     ┌─────────────────┐
│   HUSDToken     │◄───┤   HManager     │────►│   HUSDVault     │
│   (Immutable)   │    │  (Upgradeable)   │     │ (ERC4626/7540)  │
└─────────────────┘    └──────────────────┘     └─────────────────┘
        │                        │                        │
        │                        ▼                        │
        │              ┌──────────────────┐               │
        │              │   Off-Chain      │               │
        └──────────────┤   Systems        │◄──────────────┘
                       │ MPC + MetaVault  │
                       └──────────────────┘
```

#### **HUSDToken Contract**
- **Type:** Immutable ERC20 Token
- **Purpose:** Core stablecoin that users hold and trust
- **Functions:** Standard ERC20 + controlled mint/burn

#### **HManager Contract** 
- **Type:** Upgradeable entry point with comprehensive functionality
- **Purpose:** Single contract for all protocol interactions
- **Features:**
  - Multi-collateral support (USDC, ETH, BTC, SOL, etc.)
  - Institution minting/burning with Merkle whitelist
  - Asset management and off-chain integration
  - Emergency controls and admin functions

#### **HUSDVault Contract**
- **Type:** ERC4626/ERC7540 compliance layer
- **Purpose:** Standard vault interface for DeFi integrations
- **Features:**
  - ERC4626 compliant for public staking
  - ERC7540 async request/claim pattern
  - Clean accounting separation

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Git
- Node.js (for additional tooling)

### Installation

```bash
# Clone the repository
git clone https://github.com/H3liaw/HToken
cd HToken

# Install dependencies
forge install

# Copy environment file
cp .env.example .env
```

### Build

```bash
# Compile contracts
forge build

# Run tests
forge test

# Run tests with gas reports
forge test --gas-report

```


## 📋 Contract Interfaces

### HManager Functions

```solidity
// MINTING & REDEMPTION (Institutions)
function mintKUSD(address asset, uint256 amount, address receiver, bytes32[] calldata proof) external;
function redeemKUSD(uint256 kusdAmount, address asset, address receiver, bytes32[] calldata proof) external;

// ASSET MANAGEMENT
function addSupportedAsset(address asset, uint256 maxPerBlock, uint256 instantLimit) external;
function updateAssetConfig(address asset, uint256 maxPerBlock, uint256 instantLimit) external;

// OFF-CHAIN INTEGRATION
function updatePositions(address asset, uint256 mpcBalance, uint256 metaBalance, uint256 yield) external;
function distributeYield(address asset, uint256 amount) external;

// VIEW FUNCTIONS
function getSupportedAssets() external view returns (address[] memory);
function getTotalValue() external view returns (uint256);
function getSharePrice() external view returns (uint256);
```

### HUSDVault Functions (ERC4626/ERC7540)

```solidity
// ERC4626 STANDARD
function deposit(uint256 assets, address receiver) external returns (uint256 shares);
function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
function totalAssets() external view returns (uint256);

// ERC7540 ASYNC PATTERN
function requestDeposit(uint256 assets, address receiver) external returns (uint256 requestId);
function requestRedeem(uint256 shares, address receiver) external returns (uint256 requestId);
```

## 🧪 Testing

Our test suite covers:

- **Unit Tests:** Individual contract functionality
- **Integration Tests:** Cross-contract interactions
- **Fork Tests:** Mainnet state testing
- **Fuzz Tests:** Property-based testing
- **Invariant Tests:** Protocol invariant validation

```bash
# Run all tests
forge test

# Run with coverage
forge coverage

# Run invariant tests
forge test --match-contract Invariant

# Run fork tests
forge test --match-contract Fork --fork-url $MAINNET_RPC_URL
```

## 🛡️ Security

### Access Control (Solady OwnableRoles)

- **Owner:** Ultimate admin (manage roles and whitelist)
- **REPORTER_ROLE:** Off-chain systems reporting positions
- **EMERGENCY_ROLE:** Emergency pause capabilities
- **COMPLIANCE_ROLE:** User restriction management
- **REBALANCER_ROLE:** Asset allocation adjustments

### Security Features

- **Immutable Token:** Core token contract never changes
- **Merkle Whitelist:** Gas-efficient institutional access
- **Emergency Controls:** Granular pause mechanisms
- **Multi-Collateral Risk:** Diversified asset exposure
- **Professional Auditing:** Multiple security reviews

## 📊 Economics

### Supported Assets
- USDC (Primary stablecoin)
- ETH (Native Ethereum)
- WBTC (Wrapped Bitcoin)
- Additional assets via governance

### Revenue Sources
- Trading profits from MPC strategies
- DeFi yields from MetaVault
- Cross-asset arbitrage opportunities

## 🔧 Development

### Project Structure

```
├── src/
│   ├── HManager.sol          # Main protocol contract
│   ├── HUSDToken.sol           # Immutable token contract
│   ├── HUSDVault.sol           # ERC4626/7540 vault
│   └── interfaces/             # Contract interfaces
├── test/
│   ├── unit/                   # Unit tests
│   ├── integration/            # Integration tests
│   ├── invariant/              # Invariant tests
│   └── fork/                   # Fork tests

```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add comprehensive tests
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

I use:
- **Forge Format:** `forge fmt`
- **Solhint:** Solidity linting
- **Natspec:** Comprehensive documentation
- **Gas Optimization:** Solady libraries for efficiency


## 🚨 Disclaimer

This software is provided "as is", without warranty of any kind. Use at your own risk. Always conduct thorough testing and auditing before deploying to production.

---

**Built with ❤️ using Foundry**