// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyTokenVesting} from "src/MyTokenVesting.sol";
import {EMirERC20} from "src/EMirERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {DeployMyTokenVesting} from "script/DeployMyTokenVesting.s.sol";

contract InteractionsTest is Test {
    EMirERC20 public token;
    MyTokenVesting public tokenVesting;

    address payable public beneficiary = payable(makeAddr("beneficiary"));
    uint256 public totalAmount = 1000 * 10 ** 18;
    uint256 public cliffPeriod = 30 days;
    uint256 public vestingDuration = 360 days;
    uint256 public releaseInterval = 30 days;
    uint256 public totalPayablePeriods = (vestingDuration - cliffPeriod) / releaseInterval;

    function setUp() public {
        DeployMyTokenVesting deployer = new DeployMyTokenVesting();
        (token, tokenVesting) = deployer.run();
    }

    function testEntireTokenVesting() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);

        vm.warp(block.timestamp + cliffPeriod);
        vm.expectEmit(true, false, false, true, address(tokenVesting));
        emit MyTokenVesting.TokensReleased(beneficiary, totalAmount / totalPayablePeriods);
        tokenVesting.releaseToken(beneficiary);
        MyTokenVesting.VestingSchedule memory schedule = tokenVesting.getVestingSchedule(beneficiary);
        assertEq(token.balanceOf(beneficiary), totalAmount / totalPayablePeriods);
        assertEq(schedule.releasedAmount, totalAmount / totalPayablePeriods);
        assertEq(schedule.unReleasedAmount, totalAmount - (totalAmount / totalPayablePeriods));

        vm.expectEmit(true, false, false, true, address(tokenVesting));
        emit MyTokenVesting.VestingScheduleRevoked(beneficiary, schedule.unReleasedAmount);
        tokenVesting.revokeVestingSchedule(beneficiary);
    }
}
