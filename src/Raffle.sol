// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

//SPDX-License-Identifier : MIT
pragma solidity ^0.8.0 ;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
 error insufficient_amount();
 error insufficient_time();
 error raffle_is_not_open(); 
      
contract Raffle is VRFConsumerBaseV2,AutomationCompatibleInterface
{
    uint16 private constant requestConfirmations = 3;
    uint32 private constant numwords = 1;     
  
    uint256 private immutable i_entrancefee ;
    uint256 private immutable i_interval;
    address payable[] private s_players;
    // uint64 private immutable i_subscription_Id;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private  s_LastTimeStamp;
    address private Winner;
    // uint256 after_time = 48 hours ;
  event Entered_Raffle(address);
  event  WinnerIs(address winner);
    constructor
    (
        uint256 _price, 
        uint256 _interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator)
    {
        i_entrancefee =_price;
        i_interval = _interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit ;
         s_LastTimeStamp = block.timestamp ;
    }
    enum Raffle_State
    {
        open,
       Calculating
    }
    Raffle_State raffle ; 

    function enter_raffle(uint256 amount) external payable
    {
      require(msg.sender != address(0));
      if(amount < i_entrancefee )
      {
        revert insufficient_amount();
      }
      if(raffle!=Raffle_State.open)
      {
        revert raffle_is_not_open(); 
      }
      uint256 return_amount = amount - i_entrancefee;
      s_players.push(payable(msg.sender));
      emit Entered_Raffle(msg.sender);
      if(return_amount > 0)
      payable(msg.sender).transfer(return_amount);
        
    }
      function checkUpkeep(bytes memory ) public view returns (bool upkeepNeeded, bytes memory performData)
        {
        bool has_timestamp = (block.timestamp - s_LastTimeStamp) < i_interval ;
        bool has_players = s_players.length > 0 ;
        bool has_state =Raffle_State.open == raffle;
        bool hasBalance = address(this).balance > 0;
          upkeepNeeded = (has_timestamp && has_players && has_state && hasBalance);
          return(upkeepNeeded , "0x0");
        }
        function performUpkeep(bytes calldata ) external override
        {
               (bool upkeepNeeded, ) = checkUpkeep("");

             require(upkeepNeeded);
        if((block.timestamp - s_LastTimeStamp) < i_interval ) {
            raffle = Raffle_State.Calculating;
            i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            requestConfirmations,
            i_callbackGasLimit,
            numwords) ; 
             }
          }

function fulfillRandomWords(
    uint256 /* requestId */,
    uint256[] memory randomWords
) internal override {
    uint256 IndexOfWinner = randomWords[0] % s_players.length;
    address payable winner = s_players[IndexOfWinner];
    Winner = winner ;
    s_players = new address payable[](0);
       raffle= Raffle_State.Calculating;
       s_LastTimeStamp = block.timestamp;
       winner.transfer(address(this).balance);
       emit WinnerIs(winner);
    }
    
    function getstate() external returns(Raffle_State)
    {
        return raffle ;
    }
  
    function getLastTimeStamp() public view returns (uint256) {
        return s_LastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entrancefee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
    function getNumWords() public pure returns (uint256) {
        return numwords;
    }
    function getPlayer(uint256 index) public view returns (address) {
      return s_players[index];
  }
  function getRecentWinner() public view returns (address) {
    return Winner;
}

  }