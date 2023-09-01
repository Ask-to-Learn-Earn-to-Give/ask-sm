// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProblemSolver {
    // Data structure to represent a problem
    struct Problem {
        uint id;
        string title;
        string image;
        string description;
        address payable user;
        address selectedExpert;
        uint cost;
        bool solved;
        bool markedAsSolved;
        bool selecting;
    }

    // Data structure to represent an expert bid
    struct ExpertBid {
        uint bidId;
        uint problemId;
        address expert;
        uint bidAmount;
        string expertDescription;
    }

    // Store all problems
    Problem[] public problems;

    // Mapping to track expert bids for a problem
    mapping(uint => ExpertBid[]) public problemBids;

    // Mapping to track the balance of the smart contract
    mapping(address => uint) public contractBalances;
    // Event to log when a new problem is created
    event ProblemCreated(uint indexed problemId, string title, address user);

    // Event to log when an expert places a bid on a problem
    event BidPlaced(
        uint indexed problemId,
        uint indexed bidId,
        address expert,
        uint bidAmount
    );

    // Event to log when an expert is selected for a problem
    event ExpertSelected(uint indexed problemId, address selectedExpert);

    // Event to log when a problem is marked as solved by the user
    event ProblemSolved(
        uint indexed problemId,
        address user,
        address selectedExpert,
        uint cost
    );

    // Event to log when a problem is marked as unsolved by the user
    event ProblemUnsolved(uint indexed problemId, address user, uint cost);

    // Event to log when a transfer of funds is made from the contract to an expert
    event FundsTransferred(uint indexed problemId, address expert, uint amount);

    // Event to log when a refund is made to a user
    event Refund(uint indexed problemId, address user, uint amount);

    // Function to create a new problem
    function createProblem(
        string memory _title,
        string memory _image,
        string memory _description
    ) public {
        uint problemId = problems.length;
        Problem memory newProblem = Problem(
            problemId,
            _title,
            _image,
            _description,
            payable(msg.sender),
            address(0),
            0,
            false,
            false,
            false
        );
        problems.push(newProblem);
        emit ProblemCreated(problemId, _title, msg.sender);
    }

    // Function for experts to bid on a problem
    function placeBid(
        uint _problemId,
        uint _bidAmount,
        string memory _expertDescription
    ) public {
        require(_problemId < problems.length, "Invalid problem ID");
        Problem storage problem = problems[_problemId];
        require(!problem.solved, "Problem already solved");
        require(
            !_hasBid(_problemId, msg.sender),
            "Expert has already placed a bid"
        );
        uint bidId = problemBids[_problemId].length;
        ExpertBid memory newBid = ExpertBid(
            bidId,
            _problemId,
            msg.sender,
            _bidAmount,
            _expertDescription
        );
        problemBids[_problemId].push(newBid);
        emit BidPlaced(_problemId, bidId, msg.sender, _bidAmount);
    }

    // check expert have bid on this problem id or not
    function _hasBid(
        uint _problemId,
        address _expert
    ) private view returns (bool) {
        ExpertBid[] storage bids = problemBids[_problemId];
        for (uint i = 0; i < bids.length; i++) {
            if (bids[i].expert == _expert) {
                return true;
            }
        }
        return false;
    }

    function getExpertBidId(
        uint _problemId,
        address _expert
    ) public view returns (uint id) {
        ExpertBid[] storage bids = problemBids[_problemId];

        for (uint i = 0; i < bids.length; i++) {
            if (bids[i].expert == _expert) {
                return id = bids[i].bidId;
            }
        }
        // If no bid was found for this problem and expert, revert
        revert();
    }

    // Function to select an expert and transfer funds
    function selectExpert(uint _problemId, uint _bidId) public payable {
        require(_problemId < problems.length, "Invalid problem ID");

        Problem storage problem = problems[_problemId];
        // User can selected expert only one time

        require(
            msg.sender == payable(problem.user),
            "Only the user can select an expert"
        );
        require(!problem.selecting, "You have selected one");

        ExpertBid[] storage bids = problemBids[_problemId];
        require(_bidId < bids.length, "Invalid bid ID");
        ExpertBid storage selectedBid = bids[_bidId];

        problem.selectedExpert = selectedBid.expert;
        problem.cost = selectedBid.bidAmount;

        // Transfer the cost directly to the smart contract
        require(msg.value == problem.cost, "Insufficient funds");
        payable(address(this)).transfer(problem.cost);
        // selected
        problem.selecting = true;
        emit ExpertSelected(_problemId, selectedBid.expert);
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
        require(problem.selecting, "You was not selected expert");

        problem.markedAsSolved = true;
        // Transfer funds to the selected expert
        transferFundsToExpert(_problemId, _selectedExpert);
        emit ProblemSolved(
            _problemId,
            problem.user,
            _selectedExpert,
            problem.cost
        );
    }

    // Function for the user to mark the problem as unsolved and trigger refund to user
    function unSolvedProblem(uint _problemId) public {
        require(_problemId < problems.length, "Invalid problem ID");
        Problem storage problem = problems[_problemId];
        require(problem.selecting, "You was not selected expert");

        require(!problem.markedAsSolved, "Problem is already marked as solved");
        require(
            msg.sender == problem.user,
            "Only the user who created the problem can mark it as unsolved"
        );
        problem.markedAsSolved = true;
        // Transfer funds back to the user
        refundUser(_problemId);
        emit ProblemUnsolved(_problemId, problem.user, problem.cost);
    }

    // Internal function to transfer funds from the contract to the selected expert
    function transferFundsToExpert(
        uint _problemId,
        address payable _selectedExpert
    ) internal {
        Problem storage problem = problems[_problemId];
        require(problem.selecting, "You was not selected expert");
        require(problem.markedAsSolved, "Problem is not marked as solved");
        uint amount = address(this).balance;
        require(amount >= problem.cost, "Insufficient funds in the contract");
        // Transfer the cost from smart contract to expert
        payable(_selectedExpert).transfer(problem.cost);
        emit FundsTransferred(_problemId, _selectedExpert, problem.cost);
    }

    // Internal function to refund the user if a problem remains unsolved
    function refundUser(uint _problemId) internal {
        Problem storage problem = problems[_problemId];
        require(problem.markedAsSolved, "Problem is not marked as solved");
        // Refund the user the cost of the problem
        payable(problem.user).transfer(problem.cost);
        emit Refund(_problemId, problem.user, problem.cost);
    }

    // Function to get problem details
    function getProblem(
        uint _problemId
    )
        public
        view
        returns (
            string memory title,
            string memory image,
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
            problem.image,
            problem.description,
            problem.user,
            problem.selectedExpert,
            problem.cost,
            problem.solved
        );
    }

    function getBids(uint _problemId) public view returns (ExpertBid[] memory) {
        require(_problemId < problems.length, "Invalid problem ID");
        return problemBids[_problemId];
    }

    // Function to get all problems
    function getAllProblems() public view returns (Problem[] memory) {
        return problems;
    }

    receive() external payable {}

    fallback() external payable {}
}
