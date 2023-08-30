// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {ProblemSolver} from "../src/ProblemSolver.sol";
import {DeployProblemSolver} from "../script/DeployProblemSolver.s.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";

contract ProblemSolverTest is StdCheats, Test {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;
    ProblemSolver public problemSolver;
    DeployProblemSolver public deployer;

    uint256 STARTING_AMOUNT = 100 ether;
    address public deployerAddress;
    address public bob;
    address public alice;
    address public user;
    uint256 SEND_VALUE = 10 ether;

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
        vm.deal(alice, STARTING_AMOUNT);
        vm.deal(user, STARTING_AMOUNT);
        vm.deal(deployerAddress, STARTING_AMOUNT);
    }

    // test create problem
    function testCreateProblem() public {
        // setup bob create problem
        vm.prank(bob);
        // create problem
        problemSolver.createProblem(
            "Bob title test 1",
            "image url 1",
            "bob describle him problem 1"
        );
        // get all problem has crete
        ProblemSolver.Problem[] memory problems = problemSolver
            .getAllProblems();
        // assert that leng = 1
        assert(problems.length == 1);
        assert(problems[0].id == 0);
        assert(problems[0].user == address(bob));
    }

    // test place bid
    function testPlaceBid() public {
        // setup user create problem
        vm.prank(user);
        // create problem
        problemSolver.createProblem(
            "Bob title test 1",
            "image url 1",
            "bob describle him problem 1"
        );
        // setup alice bid
        vm.prank(alice);
        problemSolver.placeBid(0, 10, "Alice");
        // setup alice bid
        vm.prank(bob);
        problemSolver.placeBid(0, 20, "Bob");
        // get all bidder by id =0  created by user
        ProblemSolver.ExpertBid[] memory bidder = problemSolver.getBids(0);
        // asset
        assert(bidder[0].expert == address(alice));
        assert(bidder[0].bidAmount == 10);
        assert(bidder[1].expert == address(bob));
        assert(bidder[1].bidAmount == 20);
    }

    // test select expert
    function testSelectExpert() public {
        // setup user create problem
        vm.prank(user);
        // create problem
        problemSolver.createProblem(
            "Bob title test 1",
            "image url 1",
            "bob describle him problem 1"
        );
        // setup alice bid
        vm.prank(alice);
        problemSolver.placeBid(0, SEND_VALUE, "Alice");
        // setup alice bid
        vm.prank(bob);
        problemSolver.placeBid(0, SEND_VALUE, "Bob");
        // setup user call this select expert function
        vm.prank(user);
        // select alice with problem id =0, bidid =0, send SEND_VALUE to smart contract
        problemSolver.selectExpert{value: SEND_VALUE}(0, 0);
        // checkbalance of User = startAmount - sendvalue
        assert(address(user).balance == STARTING_AMOUNT - SEND_VALUE);
        // check balance of contract = send value
        assert(address(problemSolver).balance == SEND_VALUE);
    }

    // function test solved problem
    function testSolvedProblem() public {
        // setup user create problem
        vm.prank(user);
        // create problem
        problemSolver.createProblem(
            "Bob title test 1",
            "image url 1",
            "bob describle him problem 1"
        );
        // setup alice bid
        vm.prank(alice);
        problemSolver.placeBid(0, SEND_VALUE, "Alice");
        // setup alice bid
        vm.prank(bob);
        problemSolver.placeBid(0, SEND_VALUE, "Bob");
        // setup user call this select expert function
        vm.prank(user);
        // select alice with problem id =0, bidid =0, send SEND_VALUE to smart contract
        problemSolver.selectExpert{value: SEND_VALUE}(0, 0);
        // setup user call this select expert function
        vm.prank(user);
        // user mark as problem has solved:
        problemSolver.solvedProblem(0, payable(address(alice)));
        // check balance of alice = start value + send value
        assert(address(alice).balance == STARTING_AMOUNT + SEND_VALUE);
        // and balance of this contract = 0
        assert(address(problemSolver).balance == 0);
        // check that user can call unSolveProblem or not:
        vm.prank(user);
        // if user call solved, he/she can not call unSolved
        vm.expectRevert("Problem is already marked as solved");
        problemSolver.unSolvedProblem(0);
    }

    function testUnsolvedProblem() public {
        // setup user create problem
        vm.prank(user);
        // create problem
        problemSolver.createProblem(
            "Bob title test 1",
            "image url 1",
            "bob describle him problem 1"
        );
        // setup alice bid
        vm.prank(alice);
        problemSolver.placeBid(0, SEND_VALUE, "Alice");
        // setup alice bid
        vm.prank(bob);
        problemSolver.placeBid(0, SEND_VALUE, "Bob");
        // setup user call this select expert function
        vm.prank(user);
        // select alice with problem id =0, bidid =0, send SEND_VALUE to smart contract
        problemSolver.selectExpert{value: SEND_VALUE}(0, 0);
        // setup user call this select expert function
        vm.prank(user);
        // user mark as problem has unsolved:
        problemSolver.unSolvedProblem(0);
        // refund to user
        assert(address(user).balance == STARTING_AMOUNT);
        // and balance of this contract = 0
        assert(address(problemSolver).balance == 0);
    }
}
