// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Lottery {
    uint256 public phaseStartTime;
    uint16 public winningNumber;

    mapping(address => uint256) claimable;
    mapping(address => uint16) bet;
    mapping(address => bool) isBet;

    address[] public participants;

    constructor() {
        phaseStartTime = block.timestamp;
    }

    function buy(uint16 _number) public payable {
        require(msg.value == 0.1 ether, "You can only buy with exactly 0.1 ether");
        require(block.timestamp < (phaseStartTime + 24 hours), "The Selling phase has ended");
        require(isBet[msg.sender] != true, "You can only place one bet per phase");

        participants.push(msg.sender);
        bet[msg.sender] = _number;
        isBet[msg.sender] = true;
    }

    function generateWinningNumber() internal view returns (uint16) {
        return uint16(uint256( 
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    block.number
                )
            )
        ) % 65536);
    }

    function draw() public {
        require(block.timestamp >= (phaseStartTime + 24 hours), "Not Drawable: The Selling Phase is still ongoing");
        winningNumber = generateWinningNumber();

        uint256 winnerCount;
        uint256 length = participants.length;
        address[] memory winners = new address[](length);

        for (uint256 i = 0; i < length; ++i) {
            if (bet[participants[i]] == winningNumber && isBet[participants[i]] == true) {
                winners[winnerCount] = participants[i];
                ++winnerCount;
            }
        }

        if (winnerCount > 0) {
            uint256 prizePerWinner = address(this).balance / winnerCount;
            for (uint256 i = 0; i < winnerCount; ++i) {
                claimable[winners[i]] += prizePerWinner;
            }
        }
    }

    function claim() public {
        require(block.timestamp >= (phaseStartTime + 24 hours), "Not Claimable: The Selling Phase is still ongoing");
        if (claimable[msg.sender] != 0) {
            uint256 prize = claimable[msg.sender];
            claimable[msg.sender] = 0;
            (bool success, ) = msg.sender.call{ value: prize }("");
            require(success, "Claim failed: Unable to send the prize");
        }

        uint256 length = participants.length;
        bool isAllClaimed = true;

        for(uint256 i = 0; i < length; ++i) {
            if (claimable[participants[i]] != 0) {
                isAllClaimed = false;
                break;
            }
        }

        if (isAllClaimed) {
            for(uint256 i = 0; i < length; ++i)  {
                bet[participants[i]] = 0;
                isBet[participants[i]] = false;
            }

            delete participants;

            phaseStartTime = block.timestamp;
        }
    }
}