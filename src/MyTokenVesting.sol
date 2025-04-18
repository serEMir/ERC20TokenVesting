// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MyTokenVesting is Ownable {
    /* Errors */
    error MyTokenVesting__TokenAddressCannotBeZero();
    error MyTokenVesting__BeneficiaryAddressCannotBeZero();
    error MyTokenVesting__TotalAmountMustBeGreaterThanZero();
    error MyTokenVesting__VestingDurationMustBeGreaterThanCliffPeriod();
    error MyTokenVesting__BeneficiaryAlreadyExists();
    error MyTokenVesting__ScheduleAlreadyRevoked();
    error MyTokenVesting__NoScheduleFound();
    error MyTokenVesting__EnoughTimeNotPassedSinceLastRelease();
    error MyTokenVesting__NoTokenVested();

    /* Type Declarations */
    struct VestingSchedule {
        uint256 allotedAmount;
        uint256 releasedAmount;
        uint256 unReleasedAmount;
        uint256 startTime;
        uint256 cliffPeriod;
        uint256 vestingDuration;
        uint256 lastReleaseTime;
        uint256 releaseInterval;
        bool revoked;
    }

    /* State Variables */
    IERC20 public immutable token;
    mapping(address beneficiary => VestingSchedule) public vestingSchedules;

    /* Events */
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingScheduleRevoked(address indexed beneficiary, uint256 amount);
    event BeneficiaryAdded(
        address indexed beneficiary,
        uint256 allotedAmount,
        uint256 cliffPeriod,
        uint256 vestingDuration,
        uint256 releaseInterval
    );

    /* Constructor */
    constructor(IERC20 _token) Ownable(msg.sender) {
        if (address(_token) == address(0)) {
            revert MyTokenVesting__TokenAddressCannotBeZero();
        }
        token = _token;
    }

    function addBeneficiary(
        address _beneficiary,
        uint256 _allotedAmount,
        uint256 _cliffPeriod,
        uint256 _vestingDuration,
        uint256 _releaseInterval
    ) external onlyOwner {
        if (_beneficiary == address(0)) {
            revert MyTokenVesting__BeneficiaryAddressCannotBeZero();
        }
        if (_allotedAmount <= 0) {
            revert MyTokenVesting__TotalAmountMustBeGreaterThanZero();
        }
        if (_vestingDuration <= _cliffPeriod) {
            revert MyTokenVesting__VestingDurationMustBeGreaterThanCliffPeriod();
        }
        if (vestingSchedules[_beneficiary].allotedAmount > 0) {
            revert MyTokenVesting__BeneficiaryAlreadyExists();
        }

        vestingSchedules[_beneficiary] = VestingSchedule({
            allotedAmount: _allotedAmount,
            releasedAmount: 0,
            unReleasedAmount: _allotedAmount,
            startTime: block.timestamp,
            cliffPeriod: _cliffPeriod,
            vestingDuration: _vestingDuration,
            lastReleaseTime: 0,
            releaseInterval: _releaseInterval,
            revoked: false
        });

        require(
            token.transferFrom(msg.sender, address(this), _allotedAmount),
            "Token transfer failed"
        );

        emit BeneficiaryAdded(
            _beneficiary,
            _allotedAmount,
            _cliffPeriod,
            _vestingDuration,
            _releaseInterval
        );
    }

    function releaseToken(address payable _beneficiary) public onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        if (schedule.startTime == 0) {
            revert MyTokenVesting__NoScheduleFound();
        }
        if (schedule.revoked) {
            revert MyTokenVesting__ScheduleAlreadyRevoked();
        }
        if (
            block.timestamp <
            schedule.lastReleaseTime + schedule.releaseInterval
        ) {
            revert MyTokenVesting__EnoughTimeNotPassedSinceLastRelease();
        }

        uint256 vested = calculateVestedAmount(_beneficiary);

        if (vested == 0) {
            revert MyTokenVesting__NoTokenVested();
        } else {
            schedule.unReleasedAmount -= vested;
            schedule.releasedAmount += vested;
            schedule.lastReleaseTime = block.timestamp;
            require(
                token.transfer(_beneficiary, vested),
                "Token transfer failed"
            );
        }

        emit TokensReleased(_beneficiary, vested);
    }

    function revokeVestingSchedule(address payable _beneficiary) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        if (schedule.startTime == 0) {
            revert MyTokenVesting__NoScheduleFound();
        }
        if (schedule.revoked) {
            revert MyTokenVesting__ScheduleAlreadyRevoked();
        }

        if (
            block.timestamp >
            schedule.lastReleaseTime + schedule.releaseInterval
        ) {
            uint256 vested = calculateVestedAmount(_beneficiary);
            if (vested > 0) {
                schedule.unReleasedAmount -= vested;
                schedule.releasedAmount += vested;
                schedule.lastReleaseTime = block.timestamp;
                require(
                    token.transfer(_beneficiary, vested),
                    "Token transfer failed"
                );
                emit TokensReleased(_beneficiary, vested);
            }
            uint256 unreleased = schedule.unReleasedAmount;
            schedule.unReleasedAmount = 0;
            schedule.revoked = true;
            require(
                token.transfer(owner(), unreleased),
                "Token transfer failed"
            );
            emit VestingScheduleRevoked(_beneficiary, unreleased);
            return;
        }

        uint256 unVested = schedule.unReleasedAmount;
        schedule.revoked = true;
        schedule.unReleasedAmount = 0;

        require(token.transfer(owner(), unVested), "Token transfer failed");

        emit VestingScheduleRevoked(_beneficiary, unVested);
    }

    function calculateVestedAmount(
        address _beneficiary
    ) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        if (block.timestamp < schedule.startTime + schedule.cliffPeriod) {
            return 0;
        } else if (
            block.timestamp >= schedule.startTime + schedule.vestingDuration
        ) {
            return schedule.unReleasedAmount;
        } else {
            uint256 totalPayablePeriods = (schedule.vestingDuration -
                schedule.cliffPeriod) / schedule.releaseInterval;
            uint256 tokensPerPeriod = schedule.allotedAmount /
                totalPayablePeriods;

            return tokensPerPeriod;
        }
    }

    function getCliffPeriodLeft(
        address _beneficiary
    ) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        if (block.timestamp < schedule.startTime + schedule.cliffPeriod) {
            return
                (schedule.startTime + schedule.cliffPeriod) - block.timestamp;
        } else {
            return 0;
        }
    }

    function getVestingDurationLeft(
        address _beneficiary
    ) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        if (block.timestamp < schedule.startTime + schedule.vestingDuration) {
            return
                (schedule.startTime + schedule.vestingDuration) -
                block.timestamp;
        } else {
            return 0;
        }
    }

    function getVestingSchedule(
        address _beneficiary
    ) external view returns (VestingSchedule memory) {
        return vestingSchedules[_beneficiary];
    }
}
