// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz{
    struct Quiz_item {
        uint id;
        string question;
        string answer;
        uint min_bet;
        uint max_bet;
    }

    mapping(address => uint256)[] public bets;
    mapping(address => bool)[] public solved; // self-declared
    uint public vault_balance;
    Quiz_item[] public Quiz_itemArr; // self-declared

    constructor () {
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    function addQuiz(Quiz_item memory q) public {
        require(msg.sender != address(1), "sender should not be address 1");

        Quiz_itemArr.push(q);
    }

    function getAnswer(uint quizId) public view returns (string memory){
        return Quiz_itemArr[quizId - 1].answer;
    }

    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        Quiz_item memory q = Quiz_itemArr[quizId - 1];
        q.answer = "";
        return q;
    }

    function getQuizNum() public view returns (uint){
        return Quiz_itemArr[Quiz_itemArr.length - 1].id;
    }

    function betToPlay(uint quizId) public payable {
        if (bets.length < quizId) {
            for (uint i = 0; i <= quizId; ++i) {
                bets.push();
            }
        }

        require(msg.value >= Quiz_itemArr[quizId - 1].min_bet, "you should bet at least minimum bet value");
        require(msg.value <= Quiz_itemArr[quizId - 1].max_bet, "you should bet at most maximum bet value");

        bets[quizId - 1][msg.sender] += msg.value;
    }

    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        if(keccak256(abi.encodePacked(Quiz_itemArr[quizId - 1].answer)) == keccak256(abi.encodePacked(ans))) {
            if (solved.length < quizId) {
                for (uint i = 0; i <= quizId; ++i) {
                    solved.push();
                }
            }

            solved[quizId][msg.sender] = true;

            return true;
        }

        vault_balance += bets[quizId - 1][msg.sender];
        bets[quizId - 1][msg.sender] = 0;

        return false;
    }

    function claim() public {
        uint256 prize;
        uint256 length = Quiz_itemArr.length;
        
        for (uint i = 0; i < length; ++i) {
            if (solved[i + 1][msg.sender]) {
                prize += (bets[i][msg.sender] * 2); 
            }
        }

        require(prize != 0, "you are not claimable");
        vault_balance -= prize;
        (bool success, ) = msg.sender.call{ value: prize }("");
        require(success, "claim has failed");
    }

    receive() external payable { // self-implemented
        vault_balance += msg.value;
    } 
}