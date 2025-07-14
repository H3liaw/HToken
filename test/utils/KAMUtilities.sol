// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library KAMUtilities {
    function calculateInterest(uint256 principal, uint256 rate, uint256 time) internal pure returns (uint256) {
        return (principal * rate * time) / (365 days * 10000);
    }
    
    function calculateCollateralRatio(uint256 collateral, uint256 debt, uint256 price) internal pure returns (uint256) {
        if (debt == 0) return type(uint256).max;
        return (collateral * price * 10000) / debt;
    }
    
    function calculateLiquidationPrice(uint256 collateral, uint256 debt, uint256 minCollateralRatio) internal pure returns (uint256) {
        if (collateral == 0) return 0;
        return (debt * minCollateralRatio) / (collateral * 10000);
    }
} 