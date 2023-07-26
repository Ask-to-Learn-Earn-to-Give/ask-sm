// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {ToppicPlatform} from "../src/ToppicPlatform.sol";
import {DeploytopicPlatform} from "../script/DeployToppicPlatform.s.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";
import {ToppicPlatformToken} from "../src/ToppicPlatformToken.sol";

contract TestDao is StdCheats, Test {
    ToppicPlatform public toppicPlatform;
    DeploytopicPlatform public deployer;
    ToppicPlatformToken public topicToken;

    uint256 constant STARTING_AMOUNT = 100 ether;
    address public deployerAddress;
    address public bob;
    address public alice;
    address public user;
    uint256 constant SEND_VALUE = 1 ether;

    function setUp() external {
        deployer = new DeploytopicPlatform();
        toppicPlatform = deployer.run();
        topicToken = new ToppicPlatformToken();
        bob = makeAddr("bob");
        user = makeAddr("user");
        vm.deal(bob, STARTING_AMOUNT);
        vm.deal(user, STARTING_AMOUNT);
        vm.deal(deployerAddress, STARTING_AMOUNT);
        deployerAddress = vm.addr(deployer.deployerKey());
        // console.log("deploy address", deployerAddress);
    }

    function testCreateTopic() public {}

    receive() external payable {}

    fallback() external payable {}
}
