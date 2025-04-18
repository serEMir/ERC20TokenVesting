// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {EMirERC20} from "src/EMirERC20.sol";
import {MyTokenVesting} from "src/MyTokenVesting.sol";

contract DeployMyTokenVesting is Script {
    uint256 constant INITIAL_SUPPLY = 1000000;

    function run() public returns (EMirERC20, MyTokenVesting) {
        vm.startBroadcast();
        EMirERC20 token = new EMirERC20(INITIAL_SUPPLY);
        console.log("Token deployed at: ", address(token));

        MyTokenVesting tokenVesting = new MyTokenVesting(token);
        console.log("MyTokenVesting deployed at: ", address(tokenVesting));

        token.approve(address(tokenVesting), INITIAL_SUPPLY * (10 ** token.decimals()));
        console.log("Approved MyTokenVEsting to manage tokens");
        vm.stopBroadcast();

        console.log("MyTokenVesting Owner: ", tokenVesting.owner());

        return (token, tokenVesting);
    }
}
