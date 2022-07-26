pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import './ExampleExternalContract.sol';

/**
 * @title A staking contract
 * @author The name of the author
 *s @notice A contract that allows you yo stakie ETH
 */
contract Staker {
  // Events
  event Stake(address sender, uint256 amount);

  ExampleExternalContract public exampleExternalContract;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 3 minutes;
  mapping(address => uint256) public balances;

  /**
   * @notice Modifier that require the external contract to not be completed
   */
  modifier stakeNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, 'staking process already completed');
    _;
  }

  /**
   * @notice Modifier that require the deadline to be reached or not
   * @param required Check if the deadlin ehas reached or not
   */
  modifier deadlineReached(bool required) {
    uint256 timeRemaining = timeLeft();
    if (required) {
      require(timeRemaining == 0, 'Deadline is not reached yet');
    } else {
      require(timeRemaining > 0, 'Deadline is already reached');
    }
    _;
  }

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  receive() external payable {
    stake();
  }

  function stake() public payable deadlineReached(false) stakeNotCompleted {
    balances[msg.sender] += msg.value;

    emit Stake(msg.sender, msg.value);
  }

  function execute() public deadlineReached(true) stakeNotCompleted {
    uint256 balance_ = address(this).balance;

    require(balance_ >= threshold, "balance isn't over threshlod");

    exampleExternalContract.complete{value: balance_}();
    require(exampleExternalContract.completed(), 'execute failed');
  }

  function withdraw() public deadlineReached(true) stakeNotCompleted {
    uint256 balance_ = balances[msg.sender];

    require(balance_ > 0, 'No balance to withdraw');

    balances[msg.sender] = 0;

    (bool sent, ) = msg.sender.call{value: balance_}('');
    require(sent, 'Failed to withdraw');
  }

  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }
}
