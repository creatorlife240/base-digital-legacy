// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DigitalLegacy is ReentrancyGuard {
    struct Will {
        address nominee;
        uint256 lastHeartbeat;
        uint256 dormancyPeriod;
        bool isActive;
    }

    mapping(address => Will) public userWills;
    mapping(address => uint256) public userBalances;

    event WillUpdated(address indexed owner, address nominee);
    event HeartbeatSent(address indexed owner);
    event LegacyClaimed(address indexed owner, address nominee, uint256 amount);

    function deposit() external payable {
        userBalances[msg.sender] += msg.value;
    }

    function setWill(address _nominee, uint256 _dormancyPeriod) external {
        require(_nominee != address(0), "Invalid nominee address");
        userWills[msg.sender] = Will(_nominee, block.timestamp, _dormancyPeriod, true);
        emit WillUpdated(msg.sender, _nominee);
    }

    function heartbeat() external {
        require(userWills[msg.sender].isActive, "No active will");
        userWills[msg.sender].lastHeartbeat = block.timestamp;
        emit HeartbeatSent(msg.sender);
    }

    function claimLegacy(address _owner) external nonReentrant {
        Will storage will = userWills[_owner];
        require(will.isActive, "Will not active");
        require(msg.sender == will.nominee, "Only nominee can claim");
        require(block.timestamp > will.lastHeartbeat + will.dormancyPeriod, "Dormancy period not over");
        
        uint256 amount = userBalances[_owner];
        require(amount > 0, "No balance to claim");
        
        userBalances[_owner] = 0;
        will.isActive = false;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit LegacyClaimed(_owner, msg.sender, amount);
    }
}
