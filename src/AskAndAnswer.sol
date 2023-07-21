// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./AskToken.sol";

contract ToppicPlatform is ReentrancyGuard, Ownable {
    struct Answer {
        uint256 toppicId;
        uint256 voteUp;
        uint256 voteDown;
        address answerOwner;
        address[] voters;
    }

    struct Toppic {
        uint256 toppicId;
        string title;
        uint256 prize;
        bool isEditable;
        address topicOwner;
        uint256 creationTime;
        bool isPrizeDistributed;
    }

    mapping(uint256 => Toppic) public toppics;
    mapping(uint256 => Answer[]) public topicAnswers;
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        private answerVoter;
    uint256 public numToppics;
    mapping(address => uint256) public userPoints;
    uint256 voteCondition = 3;

    uint256 topicPoint = 10;
    uint256 votePoint = 1;
    address public tokenContract;
    uint256 public durationTime = 7 days;
    uint256 public totalPrize;
    uint8 rightAnswerPrizePercent = 60; // 60%
    uint8 rightVoterPrizePercent = 30; // 30%

    event Action(
        uint256 id,
        string actionType,
        address indexed executor,
        uint256 timestamp
    );

    modifier withinDuration(uint256 _topicId) {
        require(
            block.timestamp <= toppics[_topicId].creationTime + durationTime,
            "Duration time has ended"
        );
        _;
    }

    modifier onlyOwnerOrTopicOwner(uint256 _topicId) {
        require(
            msg.sender == owner() || msg.sender == toppics[_topicId].topicOwner,
            "Caller is not the contract owner or the owner of the question"
        );
        _;
    }

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    function createTopic(string memory _title, uint256 _prize) public {
        Toppic storage newToppic = toppics[numToppics];
        newToppic.toppicId = numToppics;
        newToppic.title = _title;
        newToppic.prize = _prize;
        newToppic.isEditable = true;
        newToppic.topicOwner = msg.sender;
        newToppic.creationTime = block.timestamp;
        newToppic.isPrizeDistributed = false;

        emit Action(
            newToppic.toppicId,
            "createTopic",
            newToppic.topicOwner,
            newToppic.creationTime
        );

        require(
            ERC20(tokenContract).transferFrom(
                msg.sender,
                address(this),
                _prize
            ),
            "Failed to transfer tokens to topic contract"
        );

        numToppics++;
    }

    function addAnswerToToppic(
        uint256 _topicId
    ) public withinDuration(_topicId) {
        require(_topicId < numToppics, "Invalid topic ID");

        Toppic storage topic = toppics[_topicId];
        require(topic.isEditable, "Topic is not editable");

        Answer memory newAnswer;
        newAnswer.toppicId = _topicId;
        newAnswer.voteUp = 0;
        newAnswer.voteDown = 0;
        newAnswer.answerOwner = msg.sender;

        topicAnswers[_topicId].push(newAnswer);

        emit Action(_topicId, "addAnswerToToppic", msg.sender, block.timestamp);
    }

    function vote(uint256 _topicId, uint256 _answerIndex, bool _vote) public {
        require(_topicId < numToppics, "Invalid topic ID");
        require(
            _answerIndex < topicAnswers[_topicId].length,
            "Invalid answer index"
        );

        Answer storage answer = topicAnswers[_topicId][_answerIndex];

        // Check if the voter has already voted on this answer
        require(
            !answerVoter[_topicId][_answerIndex][msg.sender],
            "Already voted on this answer"
        );

        // Update the vote count based on the vote type
        if (_vote == true) {
            answer.voteUp++;
        } else {
            answer.voteDown++;
        }

        // Update the voters array
        answer.voters.push(msg.sender);

        // Mark the voter as voted for this answer
        answerVoter[_topicId][_answerIndex][msg.sender] = true;

        emit Action(_topicId, "vote", msg.sender, block.timestamp);
    }

    // get the right answer address in duration time or after get 10 vote up
    function getRightAnswerAddress(
        uint256 _topicId
    ) public view returns (address) {
        Answer[] storage answers = topicAnswers[_topicId];
        uint256 maxVoteCount = 0;
        uint256 winnerIndex;
        bool hasRightAnswer = false;
        bool isDurationEnded = false;
        address winnerAddress;

        if (block.timestamp > toppics[_topicId].creationTime + durationTime) {
            isDurationEnded = true;
        }

        if (answers.length == 0) {
            // No one has answered the question, set the owner as the winnerAddress and transfer back the rightAnswerPrizePercent of the total prize
            address questionOwner = toppics[_topicId].topicOwner;
            winnerAddress = questionOwner;
        }

        for (uint256 i = 0; i < answers.length; i++) {
            uint256 voteCount = answers[i].voteUp - answers[i].voteDown;

            if (voteCount > voteCondition) {
                hasRightAnswer = true; // Found an answer with a vote difference of more than voteCondition

                if (voteCount > maxVoteCount) {
                    maxVoteCount = voteCount;
                    winnerIndex = i; // Update the index of the new highest vote count answer
                }
            }
        }
        if (!hasRightAnswer && isDurationEnded) {
            // Find the answer with the highest vote count
            for (uint256 i = 0; i < answers.length; i++) {
                if (answers[i].voteUp > maxVoteCount) {
                    maxVoteCount = answers[i].voteUp;
                    winnerIndex = i;
                }
            }
        }
        require(hasRightAnswer || isDurationEnded, "No RightAnswer found");
        // set winner address by winner index of answer owner
        winnerAddress = answers[winnerIndex].answerOwner;
        return winnerAddress;
    }

    // get the array of all voter who vote on the right answer
    function getRightAnswerVoters(
        uint256 _topicId
    ) public view returns (address[] memory) {
        address winnerAddress = getRightAnswerAddress(_topicId);

        require(_topicId < numToppics, "Invalid topic ID");

        Answer[] storage answers = topicAnswers[_topicId];
        uint256 rightAnswerIndex = getAnswerIndex(_topicId, winnerAddress);

        require(rightAnswerIndex < answers.length, "Right answer not found");

        Answer storage rightAnswer = answers[rightAnswerIndex];

        address[] memory voters = rightAnswer.voters;

        return voters;
    }

    function getAnswerIndex(
        uint256 _topicId,
        address _answerOwner
    ) public view returns (uint256) {
        Answer[] storage answers = topicAnswers[_topicId];
        for (uint256 i = 0; i < answers.length; i++) {
            if (answers[i].answerOwner == _answerOwner) {
                return i;
            }
        }
        revert("Answer not found");
    }

    // distribute prize to winner of answer question and voter who vote on the right answer
    function distributePrize(
        uint256 _topicId
    ) public onlyOwnerOrTopicOwner(_topicId) {
        Toppic storage toppic = toppics[_topicId];
        require(!toppic.isPrizeDistributed, "Prize already distributed");

        address winnerAddress = getRightAnswerAddress(_topicId);
        address[] memory voterAddresses = getRightAnswerVoters(_topicId);
        uint256 prizeToDistribute = toppic.prize;
        uint256 rightAnswerPrize = (prizeToDistribute *
            rightAnswerPrizePercent) / 100; // prize for the right answer
        uint256 voterRightAnswerPrize = (prizeToDistribute *
            rightVoterPrizePercent) / 100; // prize for voters

        // Check contract's token balance
        require(
            AskToken(tokenContract).balanceOf(address(this)) >=
                prizeToDistribute,
            "Insufficient contract balance"
        );

        // Transfer prize to the winner of this question with the highest vote and on duration time
        require(
            AskToken(tokenContract).transfer(winnerAddress, rightAnswerPrize),
            "Token transfer to winner failed"
        );

        // Transfer prize to voters who voted on the winner answer question
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            require(
                AskToken(tokenContract).transfer(
                    voterAddresses[i],
                    voterRightAnswerPrize / voterAddresses.length
                ),
                "Token transfer to voter failed"
            );
        }

        toppic.isPrizeDistributed = true;
    }

    // update topic
    function updateToppic(uint256 _topicId, string memory _newTitle) public {
        Toppic storage toppic = toppics[_topicId];
        if (toppic.isEditable) {
            toppic.title = _newTitle;
        }
    }

    function addPoints(address _user, uint256 _pointsToAdd) private {
        userPoints[_user] += _pointsToAdd;
    }

    function currentTime() internal view returns (uint) {
        return (block.timestamp * 1000) + 1000;
    }

    function getVoteResult(
        uint256 _topicId,
        address _answerOwner
    ) public view returns (uint256, uint256) {
        uint256 answerIndex = getAnswerIndex(_topicId, _answerOwner);
        Answer[] storage answers = topicAnswers[_topicId];
        require(answerIndex < answers.length, "Answer not found");

        uint256 upvotes = answers[answerIndex].voteUp;
        uint256 downvotes = answers[answerIndex].voteDown;

        return (upvotes, downvotes);
    }

    function setTokenContract(address _tokenContract) public onlyOwner {
        tokenContract = _tokenContract;
    }

    function setDurationTime(uint256 _durationTime) external onlyOwner {
        durationTime = _durationTime;
    }
}
