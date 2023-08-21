// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProblemSolver {
    // Data structure to represent a problem
    struct Problem {
        uint id;
        string title;
        string description;
        address payable user;
        address selectedExpert;
        uint cost;
        bool solved;
        bool markedAsSolved;
    }

    // Data structure to represent an expert bid
    struct ExpertBid {
        uint bidId;
        uint problemId;
        address expert;
        uint bidAmount;
    }

    // Store all problems
    Problem[] public problems;

    // Mapping to track expert bids for a problem
    mapping(uint => ExpertBid[]) public problemBids;

    // Mapping to track the balance of the smart contract
    mapping(address => uint) public contractBalances;

    // Function to create a new problem
    function createProblem(
        string memory _title,
        string memory _description
    ) public {
        uint problemId = problems.length;
        Problem memory newProblem = Problem(
            problemId,
            _title,
            _description,
            payable(msg.sender),
            address(0),
            0,
            false,
            false
        );
        problems.push(newProblem);
    }

    // Function for experts to bid on a problem
    function placeBid(uint _problemId, uint _bidAmount) public {
        require(_problemId < problems.length, "Invalid problem ID");
        Problem storage problem = problems[_problemId];
        require(!problem.solved, "Problem already solved");

        uint bidId = problemBids[_problemId].length;
        ExpertBid memory newBid = ExpertBid(
            bidId,
            _problemId,
            msg.sender,
            _bidAmount
        );
        problemBids[_problemId].push(newBid);
    }

    // Function to select an expert and transfer funds
    function selectExpert(uint _problemId, uint _bidId) public payable {
        require(_problemId < problems.length, "Invalid problem ID");
        Problem storage problem = problems[_problemId];
        require(
            msg.sender == payable(problem.user),
            "Only the user can select an expert"
        );

        ExpertBid[] storage bids = problemBids[_problemId];
        require(_bidId < bids.length, "Invalid bid ID");
        ExpertBid storage selectedBid = bids[_bidId];

        problem.selectedExpert = selectedBid.expert;
        problem.cost = selectedBid.bidAmount;
        // Transfer the cost directly to the smart contract
        require(msg.value == problem.cost, "Insufficient funds");
        payable(address(this)).transfer(problem.cost);
    }

    // Function for the user to mark the problem as solved and trigger the transfer of funds to the expert
    function solvedProblem(
        uint _problemId,
        address payable _selectedExpert
    ) public {
        require(_problemId < problems.length, "Invalid problem ID");
        Problem storage problem = problems[_problemId];
        require(!problem.markedAsSolved, "Problem is already marked as solved");
        require(
            msg.sender == problem.user,
            "Only the user who created the problem can mark it as solved"
        );
        problem.markedAsSolved = true;
        // Transfer funds to the selected expert
        transferFundsToExpert(_problemId, _selectedExpert);
    }

    // Function for the user to mark the problem as unsolved and trigger refund to user
    function unSolvedProblem(uint _problemId) public {
        require(_problemId < problems.length, "Invalid problem ID");
        Problem storage problem = problems[_problemId];
        require(!problem.markedAsSolved, "Problem is already marked as solved");
        require(
            msg.sender == problem.user,
            "Only the user who created the problem can mark it as unsolved"
        );
        problem.markedAsSolved = true;
        // Transfer funds back to the user
        refundUser(_problemId);
    }

    // Internal function to transfer funds from the contract to the selected expert
    function transferFundsToExpert(
        uint _problemId,
        address payable _selectedExpert
    ) internal {
        Problem storage problem = problems[_problemId];
        require(problem.markedAsSolved, "Problem is not marked as solved");
        uint amount = address(this).balance;
        require(amount >= problem.cost, "Insufficient funds in the contract");
        // Transfer the cost from smart contract to expert
        payable(_selectedExpert).transfer(problem.cost);
    }

    // Internal function to refund the user if a problem remains unsolved
    function refundUser(uint _problemId) internal {
        Problem storage problem = problems[_problemId];
        require(problem.markedAsSolved, "Problem is not marked as solved");
        // Refund the user the cost of the problem
        payable(problem.user).transfer(problem.cost);
    }

    // Function to get problem details
    function getProblem(
        uint _problemId
    )
        public
        view
        returns (
            string memory title,
            string memory description,
            address user,
            address selectedExpert,
            uint cost,
            bool solved
        )
    {
        require(_problemId < problems.length, "Invalid problem ID");
        Problem storage problem = problems[_problemId];
        return (
            problem.title,
            problem.description,
            problem.user,
            problem.selectedExpert,
            problem.cost,
            problem.solved
        );
    }

    receive() external payable {}

    fallback() external payable {}
}
