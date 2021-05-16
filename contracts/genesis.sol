pragma solidity ^0.7.6;

import "./Scoracle.sol"
import "./gameLogic.sol"

contract Genesis {
    // maps address of deployed pool contract to its organizer (sender)
    mapping(address => address) PoolsAndOrganizers;

    // number of pools that have been set up
    uint256 numPools;

    // deploy oracle and retrieve address
    Scoracle internal scoracle = new Scoracle();
    address scoracleAddr = address(scoracle);

    //function to deploy your own pool
    function createPool(address scoracleAddr,
                    address charityAddr,
                     string memory firstTeam, 
                     string memory secondTeam, 
                     uint256 team1id, 
                     uint256 team2id, 
                     uint256 gameid, 
                     uint256 betSize, 
                     uint256 quarterPoolAllocation, 
                     uint finalPoolAllocation) {
        Pool p = new Pool(scoracleAddr,
                     firstTeam, 
                     secondTeam, 
                     team1id, 
                     team2id, 
                     gameid, 
                     betSize, 
                     quarterPoolAllocation, 
                     finalPoolAllocation)
        
        address pAddr = address(p);
        PoolsAndOrganizers[pAddr] = msg.sender; 
        numPools += 1;
    }
}