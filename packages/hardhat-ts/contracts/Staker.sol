pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import './ExampleExternalContract.sol';

/// @title A staking contract
/// @author The name of the author
/// @notice A contract that allows you yo stakie ETH
contract Staker {
  // Events
  event Stake(address sender, uint256 amount);

  ExampleExternalContract public exampleExternalContract;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 30 seconds;

  bool openForWithdraw;

  mapping(address => uint256) public balances;

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // TODO: Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  function stake() public payable {
    balances[msg.sender] += msg.value;

    emit Stake(msg.sender, msg.value);
  }

  // TODO: After some `deadline` allow anyone to call an `execute()` function
  //  It should call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public {
    require(block.timestamp >= deadline, "deadline hasn't expired");

    uint256 balance_ = address(this).balance;

    if (balance_ > threshold) {
      exampleExternalContract.complete{value: balance_}();
    } else {
      openForWithdraw = true;
    }
  }

  // TODO: if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public {
    require(block.timestamp >= deadline, "deadline hasn't expired");
    require(openForWithdraw, 'Not open for withdrawal');

    uint256 balance_ = balances[msg.sender];

    // check if the user has balance to withdraw
    require(balance_ > 0, 'No balance to withdraw');

    // reset the balance of the user
    balances[msg.sender] = 0;

    // Transfer balance back to the user
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

  receive() external payable {
    stake();
  }
}
