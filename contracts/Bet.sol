// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Bet is VRFConsumerBaseV2 {
    bool private debugMode;
    uint256 private constant FAIR_ODDS = 500;
    uint256 private constant HOUSE_ODDS = 450;

    // chainlink configuration
    uint64 private constant CHAINLINK_SUB_ID = 56;
    bytes32 private constant CHAINLINK_KEY_HASH =
        0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93;
    address private constant CHAINLINK_COORD =
        0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    uint32 private constant CHAINLINK_GAS_LIMIT = 50000;
    uint16 private constant CHAINLINK_REQUESTS = 3;
    uint32 private constant CHAINLINK_NUM_WORDS = 1;

    address public getAddress;
    address payable private contractOwner;
    VRFCoordinatorV2Interface private coordinator;

    uint256[] private chainlinkRandomWords;
    uint256 private chainlinkRequestId;
    address private chainlinkOwner;

    enum OfferState {
        READY,
        WIN,
        PAID,
        CLOSED
    }

    struct Offer {
        uint64 offerId;
        OfferState state;
        address owner;
        address losser;
        uint256 ammount;
        uint256 odds;
    }

    mapping(uint64 => Offer) public offers;
    uint64 public offersSize = 0;

    constructor(bool _debugMode) VRFConsumerBaseV2(CHAINLINK_COORD) {
        coordinator = VRFCoordinatorV2Interface(CHAINLINK_COORD);
        contractOwner = payable(msg.sender);
        debugMode = _debugMode;
        getAddress = address(this);
    }

    function makeOfferAgainstHouse(uint256 ask)
        public
        payable
        returns (Offer memory)
    {
        require(msg.value == ask, "deposited incorrect ammount");

        uint64 offerId = offersSize;
        offers[offerId] = Offer(
            offersSize,
            OfferState.READY,
            address(this),
            address(this),
            msg.value * 2,
            HOUSE_ODDS
        );
        conductBet(offerId, offers[offerId].odds);
        payable(offers[offerId].owner).transfer(offers[offerId].ammount);
        offersSize++;

        return offers[offerId];
    }

    function makeOffer(uint256 ask) public payable returns (Offer memory) {
        require(msg.value == ask, "deposited incorrect ammount");
        offers[offersSize] = Offer(
            offersSize,
            OfferState.READY,
            msg.sender,
            address(this),
            msg.value,
            FAIR_ODDS
        );
        return offers[offersSize++];
    }

    function acceptOffer(uint64 offerId) public payable returns (Offer memory) {
        require(offerId <= offersSize, "offer non existant");
        require(
            offers[offerId].state == OfferState.READY,
            "offer is not ready"
        );
        require(
            offers[offerId].ammount == msg.value,
            "deposited value != offer ask"
        );

        offers[offerId].ammount += msg.value;
        conductBet(offerId, offers[offerId].odds);
        payable(offers[offerId].owner).transfer(offers[offerId].ammount);

        return offers[offerId];
    }

    function closeOffer(uint64 offerId) public payable {
        require(offerId <= offersSize, "offer non existant");
        require(
            offers[offerId].state == OfferState.READY ||
                offers[offerId].state == OfferState.WIN,
            "offer is not ready or won"
        );
        require(
            offers[offerId].owner == msg.sender,
            "you are not the offer owner"
        );

        offers[offerId].state = OfferState.CLOSED;
        payable(offers[offerId].owner).transfer(offers[offerId].ammount);
    }

    function withdraw() public {
        require(msg.sender == contractOwner, "you are not the contract owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    function conductBet(uint64 offerId, uint256 player2Odds) private {
        offers[offerId].state = OfferState.WIN;

        uint256 rand;
        if (debugMode) {
            rand = debugModeRandom();
        } else {
            requestRandomWords();
            rand = chainlinkRandomWords[0];
        }
        bool win = rand % 100 < player2Odds;
        if (win) {
            offers[offerId].owner = msg.sender;
        }
    }

    function debugModeRandom() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        offersSize
                    )
                )
            );
    }

    function requestRandomWords() private {
        chainlinkRequestId = coordinator.requestRandomWords(
            CHAINLINK_KEY_HASH,
            CHAINLINK_SUB_ID,
            CHAINLINK_REQUESTS,
            CHAINLINK_GAS_LIMIT,
            CHAINLINK_NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        chainlinkRandomWords = randomWords;
    }
}
