// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyTokenVesting} from "src/MyTokenVesting.sol";
import {EMirERC20} from "src/EMirERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {DeployMyTokenVesting} from "script/DeployMyTokenVesting.s.sol";

contract TestMyTokenVesting is Test {
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

    /*//////////////////////////////////////////////////////////////
                      TEST ADDBENEFICIARY FUNCTION
    //////////////////////////////////////////////////////////////*/

    function testAddBeneficiaryAndEmit() external {
        vm.startPrank(tokenVesting.owner());
        vm.expectEmit(true, false, false, true, address(tokenVesting));
        emit MyTokenVesting.BeneficiaryAdded(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.stopPrank();
        MyTokenVesting.VestingSchedule memory schedule = tokenVesting.getVestingSchedule(beneficiary);

        assertEq(schedule.allotedAmount, totalAmount);
        assertEq(schedule.startTime, block.timestamp);
        assertEq(schedule.cliffPeriod, cliffPeriod);
        assertEq(schedule.vestingDuration, vestingDuration);
        assertEq(schedule.releaseInterval, releaseInterval);
        assertFalse(schedule.revoked);
        assertEq(token.balanceOf(address(tokenVesting)), totalAmount);
    }

    function testAddBeneficiaryFailsIfBeneficiaryIsZero() external {
        vm.startPrank(tokenVesting.owner());
        vm.expectRevert(MyTokenVesting.MyTokenVesting__BeneficiaryAddressCannotBeZero.selector);
        tokenVesting.addBeneficiary(address(0), totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.stopPrank();
    }

    function testAddBeneficiaryFailsIfTotalAmountIsZero() external {
        vm.startPrank(tokenVesting.owner());
        vm.expectRevert(MyTokenVesting.MyTokenVesting__TotalAmountMustBeGreaterThanZero.selector);
        tokenVesting.addBeneficiary(beneficiary, 0, cliffPeriod, vestingDuration, releaseInterval);
        vm.stopPrank();
    }

    function testAddBeneficiaryFailsIfVestingDurationIsLessThanCliffPeriod() external {
        vm.startPrank(tokenVesting.owner());
        vm.expectRevert(MyTokenVesting.MyTokenVesting__VestingDurationMustBeGreaterThanCliffPeriod.selector);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, cliffPeriod - 1, releaseInterval);
        vm.stopPrank();
    }

    function testAddBeneficiaryFailsIfBeneficiaryAlreadyExists() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.expectRevert(MyTokenVesting.MyTokenVesting__BeneficiaryAlreadyExists.selector);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                         TEST RELEASE FUNCTION
    //////////////////////////////////////////////////////////////*/

    function testReleaseWorksAndEmits() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.warp(block.timestamp + cliffPeriod + releaseInterval);

        vm.expectEmit(true, false, false, true, address(tokenVesting));
        emit MyTokenVesting.TokensReleased(beneficiary, totalAmount / totalPayablePeriods);
        tokenVesting.releaseToken(beneficiary);
        MyTokenVesting.VestingSchedule memory schedule = tokenVesting.getVestingSchedule(beneficiary);
        assertEq(schedule.unReleasedAmount, totalAmount - (totalAmount / totalPayablePeriods));
        assertEq(schedule.releasedAmount, totalAmount / totalPayablePeriods);
        assertEq(schedule.lastReleaseTime, block.timestamp);
        assertEq(token.balanceOf(beneficiary), totalAmount / totalPayablePeriods);
        vm.stopPrank();
    }

    function testReleaseFailsIfScheduleNotFound() external {
        vm.startPrank(tokenVesting.owner());
        vm.expectRevert(MyTokenVesting.MyTokenVesting__NoScheduleFound.selector);
        tokenVesting.releaseToken(beneficiary);
        vm.stopPrank();
    }

    function testReleaseFailsIfCliffNotElapsed() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.warp(block.timestamp + cliffPeriod - 1);
        vm.expectRevert(MyTokenVesting.MyTokenVesting__NoTokenVested.selector);
        tokenVesting.releaseToken(beneficiary);
        vm.stopPrank();
    }

    function testReleaseFailsIfScheduleRevoked() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.warp(block.timestamp + cliffPeriod + releaseInterval);
        tokenVesting.revokeVestingSchedule(beneficiary);
        vm.expectRevert(MyTokenVesting.MyTokenVesting__ScheduleAlreadyRevoked.selector);
        tokenVesting.releaseToken(beneficiary);
        vm.stopPrank();
    }

    function testReleaseFailsIfEnoughTimeNotPassedSinceLastRelease() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.warp(block.timestamp + cliffPeriod + releaseInterval);
        tokenVesting.releaseToken(beneficiary);
        vm.expectRevert(MyTokenVesting.MyTokenVesting__EnoughTimeNotPassedSinceLastRelease.selector);
        tokenVesting.releaseToken(beneficiary);
        vm.stopPrank();
    }

    function testMultipleRelease() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.warp(block.timestamp + cliffPeriod + releaseInterval);
        tokenVesting.releaseToken(beneficiary);

        vm.warp(block.timestamp + releaseInterval);
        tokenVesting.releaseToken(beneficiary);

        MyTokenVesting.VestingSchedule memory schedule = tokenVesting.getVestingSchedule(beneficiary);
        assertEq(schedule.unReleasedAmount, totalAmount - 2 * (totalAmount / totalPayablePeriods));
        assertEq(schedule.releasedAmount, 2 * (totalAmount / totalPayablePeriods));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                          TEST REVOKE FUCNTION
    //////////////////////////////////////////////////////////////*/

    function testRevokeWorksBeforeCliffElapseAndEmits() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);

        MyTokenVesting.VestingSchedule memory schedule = tokenVesting.getVestingSchedule(beneficiary);
        uint256 unReleasedAmount = schedule.unReleasedAmount;
        vm.expectEmit(true, false, false, true, address(tokenVesting));
        emit MyTokenVesting.VestingScheduleRevoked(beneficiary, unReleasedAmount);
        tokenVesting.revokeVestingSchedule(beneficiary);
    }

    function testRevokeWorksAfterCliffElapseAndEmits() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.warp(block.timestamp + cliffPeriod);
        vm.expectEmit(true, false, false, true, address(tokenVesting));
        emit MyTokenVesting.VestingScheduleRevoked(beneficiary, (totalAmount - (totalAmount / totalPayablePeriods)));
        tokenVesting.revokeVestingSchedule(beneficiary);
    }

    function testRevokesWorksAfterReleaseAndEmits() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.warp(block.timestamp + cliffPeriod + releaseInterval);
        tokenVesting.releaseToken(beneficiary);
        MyTokenVesting.VestingSchedule memory schedule = tokenVesting.getVestingSchedule(beneficiary);
        uint256 unReleasedAmount = schedule.unReleasedAmount;
        vm.expectEmit(true, false, false, true, address(tokenVesting));
        emit MyTokenVesting.VestingScheduleRevoked(beneficiary, unReleasedAmount);
        tokenVesting.revokeVestingSchedule(beneficiary);
    }

    function testRevokeFailsIfScheduleNotFound() external {
        vm.startPrank(tokenVesting.owner());
        vm.expectRevert(MyTokenVesting.MyTokenVesting__NoScheduleFound.selector);
        tokenVesting.revokeVestingSchedule(beneficiary);
        vm.stopPrank();
    }

    function testRevokeFailsIfScheduleAlreadyRevoked() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        tokenVesting.revokeVestingSchedule(beneficiary);
        vm.expectRevert(MyTokenVesting.MyTokenVesting__ScheduleAlreadyRevoked.selector);
        tokenVesting.revokeVestingSchedule(beneficiary);
        vm.stopPrank();
    }

    function testgetCliffPeriodLeft() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.warp(block.timestamp + cliffPeriod / 2);
        uint256 cliffPeriodLeft = tokenVesting.getCliffPeriodLeft(beneficiary);
        assertEq(cliffPeriodLeft, cliffPeriod / 2);

        vm.warp(block.timestamp + cliffPeriod);
        cliffPeriodLeft = tokenVesting.getCliffPeriodLeft(beneficiary);
        assertEq(cliffPeriodLeft, 0);
        vm.stopPrank();
    }

    function testgetVestingDurationLeft() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.warp(block.timestamp + vestingDuration / 2);
        uint256 vestingDurationLeft = tokenVesting.getVestingDurationLeft(beneficiary);
        assertEq(vestingDurationLeft, vestingDuration / 2);

        vm.warp(block.timestamp + vestingDuration);
        vestingDurationLeft = tokenVesting.getVestingDurationLeft(beneficiary);
        assertEq(vestingDurationLeft, 0);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                 TEST CALCULATE VESTED AMOUNT FUNCTION
    //////////////////////////////////////////////////////////////*/

    function testCalculateVestedAmount() external {
        vm.startPrank(msg.sender);
        tokenVesting.addBeneficiary(beneficiary, totalAmount, cliffPeriod, vestingDuration, releaseInterval);
        vm.warp(block.timestamp + cliffPeriod - 1);
        uint256 noVestedAmount = tokenVesting.calculateVestedAmount(beneficiary);
        assertEq(noVestedAmount, 0);

        vm.warp(block.timestamp + releaseInterval);
        uint256 vestedAmount = tokenVesting.calculateVestedAmount(beneficiary);
        assertEq(vestedAmount, totalAmount / totalPayablePeriods);

        vm.warp(block.timestamp + vestingDuration);
        uint256 totalVestedAmount = tokenVesting.calculateVestedAmount(beneficiary);
        assertEq(totalVestedAmount, totalAmount);
        vm.stopPrank();
    }
}
