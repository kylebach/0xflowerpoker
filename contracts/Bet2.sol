/ SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Bet is VRFConsumerBaseV2 {

    struct offer {
        uint id;
        address player1;
        address player2;
        
    }

    function makeHouseOffer(uint size) {
         
    }
}