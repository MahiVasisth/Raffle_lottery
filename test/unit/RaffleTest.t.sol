//SPDX-License-Identifier : MIT
pragma solidity ^0.8.0 ;
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";
import {CreateSubscription} from "../../script/Interactions.s.sol";

contract RaffleTest is StdCheats, Test{
    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 raffleEntranceFee;
    uint256 automationUpdateInterval;
    address vrfCoordinatorV2;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
     uint256 starting_balance = 100 ether;
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
           (
            raffleEntranceFee,
            automationUpdateInterval,
            vrfCoordinatorV2, // link
            gasLane,
            subscriptionId ,
            callbackGasLimit,
            link,
              // deployerKey   
           ) = helperConfig.activeNetworkConfig();
           vm.deal(address(raffle), STARTING_USER_BALANCE);
         }
    
    function testRaffleInitializesInOpenState() public  {
        assert(raffle.getstate() == Raffle.Raffle_State.open);
    }


    function testraffle_is_not_revert_when_enough_eth_sent() public {
       vm.prank(PLAYER);
       
      raffle.enter_raffle(raffleEntranceFee);
      address playerrecorded = raffle.getPlayer(0);
      assert(playerrecorded == PLAYER);
         }  
  function testraffle_is_revert_when_enough_eth_not_sent() public{
     vm.prank(PLAYER);     
     vm.expectRevert();
        raffle.enter_raffle(0);
        }
    function test_raffle_can_not_enter_in_raffle_when_raffleiscalculating() public{
          vm.prank(PLAYER);
          raffle.enter_raffle(raffleEntranceFee);
         vm.warp(block.timestamp + automationUpdateInterval + 1);
         vm.roll(block.number + 1);
         raffle.performUpkeep("");
         Raffle.Raffle_State raffleState = raffle.getstate();
        // (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(raffleState == Raffle.Raffle_State.Calculating);
        // assert(upkeepNeeded == false);
         vm.expectRevert();
         raffle.enter_raffle(raffleEntranceFee);
        }
       
           function test_checkUpkeep_returnfalse_when_raffle_havenobalace() public{
           vm.warp(block.timestamp + automationUpdateInterval + 1);
           vm.roll(block.number + 1);
         
              (bool upkeep , ) = raffle.checkUpkeep("");
             assert(!upkeep);
              }
     function testcheckupkeepreturnfalsewhenraffleisnotopen() external{
         vm.prank(PLAYER);
         raffle.enter_raffle(raffleEntranceFee);
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number+1);
        raffle.performUpkeep("");
    
        Raffle.Raffle_State raffleState = raffle.getstate();
         (bool upkeepneeded, ) = raffle.checkUpkeep("");
         assert(raffleState == Raffle.Raffle_State.Calculating);
         assert(upkeepneeded == false);    
        }
        function testcheckupreturntruwhenparametersgood() public {
            vm.prank(PLAYER);
            raffle.enter_raffle(raffleEntranceFee);
            vm.warp(block.timestamp + automationUpdateInterval + 1);
            vm.roll(block.number + 1);
            (bool upkeepneeded, ) = raffle.checkUpkeep(""); 
            assert(upkeepneeded);
        }
  function testperformupkeeprunonlywhencheckupreturntrue() public{
        vm.prank(PLAYER);
        raffle.enter_raffle(raffleEntranceFee);
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
  }
    
  function testperformupkeeprevertsifcheckupkeepisfalse() public{
    vm.expectRevert();
    raffle.performUpkeep("");
  }
  /*
function testperformupkeepupdatesrafflestateandemitsrequestid() public {
    vm.prank(PLAYER);
    raffle.enter_raffle(raffleEntranceFee);
    vm.warp(block.timestamp+automationUpdateInterval+1);
    vm.roll(block.number+1);
    vm.recordLogs();
    raffle.performUpkeep("");
    vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];
    Raffle.Raffle_State raffleState = raffle.getstate();
    assert(uint256(requestId)>0);
    assert(uint(raffleState)==1);
}
*/
modifier raffleEntered() {
    vm.prank(PLAYER);
    raffle.enter_raffle(raffleEntranceFee);
    vm.warp(block.timestamp + automationUpdateInterval + 1);
    vm.roll(block.number + 1);
    _;
}

modifier skipFork() {
    if (block.chainid != 31337) {
        return;
    }
    _;
}

function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep()
public
raffleEntered
skipFork
{
// Arrange
// Act / Assert
vm.expectRevert("nonexistent request");
// vm.mockCall could be used here...
VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
    0,
    address(raffle)
);

vm.expectRevert("nonexistent request");

VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
    1,
    address(raffle)
);
}
         function testfulfillRandomwordspicksasawinnerresetsandsendmoney() public raffleEntered skipFork {
            address expectedwinner = address(1);
            uint256 additionalentrances = 3;
            uint256 startingindex = 1;
            for(uint256 i = startingindex ; i < startingindex + additionalentrances ; i++){
            address user = address(uint160(i));
            hoax(user , 1 ether);
            raffle.enter_raffle(raffleEntranceFee);
          }
          uint256 startingTimeStamp = raffle.getLastTimeStamp();
          uint256 startingBalance = expectedwinner.balance;
              // Act
          vm.recordLogs();
          raffle.performUpkeep(""); // emits requestId
          Vm.Log[] memory entries = vm.getRecordedLogs();
          bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs
          VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
              uint256(requestId),
              address(raffle)
          );
      address recentwinner = raffle.getRecentWinner();
      Raffle.Raffle_State rafflestate = raffle.getstate();
      uint256 winnerbalance = recentwinner.balance;
      uint256 endingtimestamp = raffle.getLastTimeStamp();
      uint256 prize = raffleEntranceFee * (additionalentrances + 1);
      assert(recentwinner == expectedwinner);
      assert(uint256(rafflestate)==0);
      assert(winnerbalance == startingBalance + prize);
      assert(endingtimestamp > startingTimeStamp);
    }
        
     

        receive() external payable{}    
}
