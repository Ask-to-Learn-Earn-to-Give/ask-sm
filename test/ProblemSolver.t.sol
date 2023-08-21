// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {ProblemSolver} from "../src/ProblemSolver.sol";
import {DeployProblemSolver} from "../script/DeployProblemSolver.s.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";

contract ToppicPlatformTokenTest is StdCheats, Test {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;
    ProblemSolver public problemSolver;
    DeployProblemSolver public deployer;

    uint256 STARTING_AMOUNT = 50 ether;
    address public deployerAddress;
    address public bob;
    address public alice;
    address public user;
    uint256 SEND_VALUE = 1 ether;

    function setUp() external {
        if (block.chainid == 31337) {
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;
        } else {
            deployerKey = vm.envUint("PRIVATE_KEY");
        }
        deployer = new DeployProblemSolver();
        problemSolver = deployer.run();

        bob = makeAddr("bob");
        alice = makeAddr("alice");
        user = makeAddr("user");

        deployerAddress = vm.addr(deployer.deployerKey());
        vm.prank(deployerAddress);
        console.log("deploy address", deployerAddress);

        vm.deal(bob, STARTING_AMOUNT);
        vm.deal(alice, 0 ether);
        vm.deal(user, STARTING_AMOUNT);
        vm.deal(deployerAddress, STARTING_AMOUNT);
    }
}
