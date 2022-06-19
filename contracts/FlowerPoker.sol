// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract FlowerPoker is VRFConsumerBaseV2 {
    uint64 private constant CHAINLINK_SUB_ID = 56;
    bytes32 private constant CHAINLINK_KEY_HASH =
        0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;
    address private constant CHAINLINK_COORD =
        0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    uint32 private constant CHAINLINK_GAS_LIMIT = 400000;
    uint16 private constant CHAINLINK_REQUESTS = 3;
    uint32 private constant CHAINLINK_NUM_WORDS = 10;

    address payable private contractOwner;
    VRFCoordinatorV2Interface private coordinator;

    constructor() VRFConsumerBaseV2(CHAINLINK_COORD) {
        coordinator = VRFCoordinatorV2Interface(CHAINLINK_COORD);
        contractOwner = payable(msg.sender);
    }

    enum MatchResult {
        WAIT,
        BUST,
        PAIR,
        TWO_PAIR,
        THREE_OF_A_KIND,
        FULL_HOUSE,
        FOUR_OF_A_KIND,
        FIVE_OF_A_KIND
    }

    enum MatchState {
        READY,
        CANCELED,
        PLANTED,
        PLAYER_ONE,
        PLAYER_TWO,
        TIE_BOTH
    }

    struct Match {
        uint256 id;
        uint256 sum;
        address player1;
        address player2;
        MatchResult player1Result;
        MatchResult player2Result;
        MatchState state;
        uint256 flowers;
        // internal only, won't be serialized
        uint8[5] player1draws;
        uint8[5] player2draws;
    }

    uint256 public matchCount = 0;
    mapping(uint256 => Match) public matches;
    mapping(uint256 => uint256) private requestIdToMatchMap;

    event offerPosted(uint256 indexed matchId, uint256 amount);
    event offerCancled(uint256 indexed matchId);
    event FlowersPlanted(uint256 indexed requestId, uint256 indexed matchId);
    event FlowersPicked(
        uint256 requestId,
        uint256 indexed matchId,
        address indexed winner,
        MatchState indexed state,
        uint256 flowers
    );

    function acceptMatch(uint256 matchId) public payable {
        require(matchCount > matchId, "Offer not made");
        require(matches[matchId].state == MatchState.READY, "Offer not ready");
        require(matches[matchId].sum == msg.value, "Offer sum not matched");
        matches[matchId].player2 = msg.sender;
        matches[matchId].sum += msg.value;
        matches[matchId].state = MatchState.PLANTED;
        uint256 requestId = coordinator.requestRandomWords(
            CHAINLINK_KEY_HASH,
            CHAINLINK_SUB_ID,
            CHAINLINK_REQUESTS,
            CHAINLINK_GAS_LIMIT,
            CHAINLINK_NUM_WORDS
        );
        requestIdToMatchMap[requestId] = matchId;
        emit FlowersPlanted(requestId, matchId);
    }

    function cancelMatch(uint256 matchId) public {
        require(matchCount > matchId, "Offer not made");
        require(matches[matchId].player1 == msg.sender, "Offer not owned");
        require(matches[matchId].state == MatchState.READY, "Offer not ready");
        matches[matchId].state == MatchState.CANCELED;
        payable(matches[matchId].player1).transfer(matches[matchId].sum);
        emit offerCancled(matchId);
    }

    function createHouseMatch(uint256 sum)
        public
        payable
        returns (uint256 matchId)
    {
        require(msg.value == sum, "deposited incorrect ammount");
        matchId = matchCount++;
        matches[matchId] = Match(
            matchId,
            sum + sum,
            msg.sender,
            address(this),
            MatchResult.WAIT,
            MatchResult.WAIT,
            MatchState.PLANTED,
            0x0,
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        );
        uint256 requestId = coordinator.requestRandomWords(
            CHAINLINK_KEY_HASH,
            CHAINLINK_SUB_ID,
            CHAINLINK_REQUESTS,
            CHAINLINK_GAS_LIMIT,
            CHAINLINK_NUM_WORDS
        );
        requestIdToMatchMap[requestId] = matchId;
        emit FlowersPlanted(requestId, matchId);
    }

    function createMatch(uint256 sum) public payable returns (uint256 matchId) {
        require(msg.value == sum, "deposited incorrect ammount");
        matchId = matchCount++;
        matches[matchId] = Match(
            matchId,
            sum,
            msg.sender,
            contractOwner,
            MatchResult.WAIT,
            MatchResult.WAIT,
            MatchState.READY,
            0x0,
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        );
        emit offerPosted(matchId, sum);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 matchId = requestIdToMatchMap[requestId];
        uint256 flowers = 0;
        for (uint8 i = 0; i < 5; i++) {
            matches[matchId].player1draws[i] = uint8(randomWords[i] % 6);
            matches[matchId].player2draws[i] = uint8(randomWords[i + 5] % 6);
        }
        for (uint8 i = 0; i < 5; i++) {
            flowers *= 10;
            flowers += (randomWords[i] % 6) + 1;
        }
        for (uint8 i = 0; i < 5; i++) {
            flowers *= 10;
            flowers += (randomWords[i + 5] % 6) + 1;
        }
        matches[matchId].player1Result = evaluateHand(matchId, true);
        matches[matchId].player2Result = evaluateHand(matchId, false);
        MatchState state = evaluateMatch(
            matches[matchId].player1Result,
            matches[matchId].player2Result
        );
        address payable winner = payable(0x0);
        if (state == MatchState.TIE_BOTH) {
            payable(matches[matchId].player1).transfer(
                matches[matchId].sum / 2
            );
            if (matches[matchId].player2 != address(this)) {
                payable(matches[matchId].player2).transfer(
                    matches[matchId].sum / 2
                );
            }
        } else {
            winner = (state == MatchState.PLAYER_ONE)
                ? payable(matches[matchId].player1)
                : payable(matches[matchId].player2);
            if (winner != address(this)) {
                winner.transfer(matches[matchId].sum);
            }
        }

        matches[matchId].state = state;
        matches[matchId].flowers = flowers;
        emit FlowersPicked(requestId, matchId, winner, state, flowers);
    }

    function evaluateHand(uint256 matchId, bool player1)
        internal
        view
        returns (MatchResult)
    {
        uint8[5] memory hand = matches[matchId].player1draws;
        if (!player1) {
            hand = matches[matchId].player2draws;
        }
        uint8[8] memory nums;
        uint8 mostId;
        uint8 mostAmt = 0;
        uint8 secondId;
        uint8 secondAmt = 0;
        for (uint8 i = 0; i < 5; i++) {
            nums[hand[i]]++;
        }
        for (uint8 i = 0; i < 8; i++) {
            if (nums[i] >= mostAmt) {
                secondId = mostId;
                secondAmt = mostAmt;
                mostId = i;
                mostAmt = nums[i];
            } else if (nums[i] >= secondAmt) {
                secondId = i;
                secondAmt = nums[i];
            }
        }
        if (mostAmt == 5) {
            return MatchResult.FIVE_OF_A_KIND;
        } else if (mostAmt == 4) {
            return MatchResult.FOUR_OF_A_KIND;
        } else if (mostAmt == 3 && secondAmt == 2) {
            return MatchResult.FULL_HOUSE;
        } else if (mostAmt == 3) {
            return MatchResult.THREE_OF_A_KIND;
        } else if (mostAmt == 2 && secondAmt == 2) {
            return MatchResult.TWO_PAIR;
        } else if (mostAmt == 2) {
            return MatchResult.PAIR;
        } else {
            return MatchResult.BUST;
        }
    }

    function evaluateMatch(MatchResult r1, MatchResult r2)
        internal
        pure
        returns (MatchState)
    {
        if (r1 > r2) {
            return MatchState.PLAYER_ONE;
        } else if (r1 == r2) {
            return MatchState.TIE_BOTH;
        } else {
            return MatchState.PLAYER_TWO;
        }
    }

    function sweep() public {
        require(msg.sender == contractOwner);
        payable(contractOwner).transfer(address(this).balance);
    }
}
