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

    uint64 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        (
            ,
            gasLane,
            automationUpdateInterval,
            raffleEntranceFee,
            callbackGasLimit,
            vrfCoordinatorV2, // link
            // deployerKey
            ,

        ) = helperConfig.activeNetworkConfig();
    }
    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getstate() == Raffle.RaffleState.open);
    }


    function testraffle_is_not_revert_when_enough_eth_sent() payable{
       vm.prank(PLAYER);
        uint256 amount = 0.5 ;
       raffle.enter_raffle(amount);
         address player1 = raffle.getPlayer(0)
       assertEq(player1 , PLAYER);
  }  
  function testraffle_is_revert_when_enough_eth_not_sent() public{
        uint256 amount = 0 ;
         raffle.enter_raffle(amount)
        vm.expectRevert("You are not Sent enough eth ");
        }
    function test_raffle_can_not_enter_in_raffle_when_close() public{
        //    raffle.Raffle_State.open
            if(raffle.getstate() != Raffle.Raffle_State.open){
            vm.expectRevert("The raffle has been closed");
           }
       
           function test_checkUpkeep_revert_when_raffle_is_close() public{
            Raffle.Raffle_State.closed;
              (bool upkeep , ) = raffle.checkUpkeep("");
              if(upkeep == false)
            vm.expectRevert("The raffle has been closed");
              }
             
            
}
