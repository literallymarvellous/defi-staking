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
  uint8 counter;
  bool openForWithdrawal;
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

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  /**
    @notice fuction calls stake() when ETH is sent directly to contract
   */
  receive() external payable {
    stake();
  }

  /**
    @notice stakes ETH
   */
  function stake() public payable deadlineReached(false) {
    balances[msg.sender] += msg.value;

    emit Stake(msg.sender, msg.value);
  }

  /**
    @notice withdraws staked ETH to external contract if threshold is met else open withdrawal
   */
  function execute() public deadlineReached(true) stakeNotCompleted {
    require(counter < 1, 'execute only called once');

    // increase number of calls for execute()
    counter++;

    uint256 balance_ = address(this).balance;

    if (balance_ >= threshold) {
      exampleExternalContract.complete{value: balance_}();
      require(exampleExternalContract.completed(), 'execute failed');
    } else {
      openForWithdrawal = true;
    }
  }

  /**
    @notice sends staked ETH back to owners since threshold wasn't met
   */
  function withdraw() public deadlineReached(true) stakeNotCompleted {
    require(openForWithdrawal, 'Withdrawal not allowed yet');

    uint256 balance_ = balances[msg.sender];
    require(balance_ > 0, 'No balance to withdraw');

    balances[msg.sender] = 0;

    (bool sent, ) = msg.sender.call{value: balance_}('');
    require(sent, 'Failed to withdraw');
  }

  /**
    @notice calculates time left till deadline
   */
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }
}
