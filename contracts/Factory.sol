// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Scoracle.sol";
import "./Pool.sol";

contract Factory {
    // maps address of organizer (sender) to its contract
    mapping(address => address) PoolsByOrganizer;

    // number of pools that have been set up
    uint256 numPools;

    address public immutable scoracle;
    constructor(address _scoracle) public {
        scoracle = _scoracle;
    }

    //function to deploy your own pool
    function createPool(
                    address payable charityAddr,
                     string memory firstTeam, 
                     string memory secondTeam, 
                     uint256 team1id, 
                     uint256 team2id, 
                     uint256 gameid, 
                     uint256 betSize, 
                     uint256 quarterPoolAllocation, 
                     uint finalPoolAllocation) public {
        Pool p = new Pool(scoracle,
                     charityAddr,
                     firstTeam, 
                     secondTeam, 
                     team1id, 
                     team2id, 
                     gameid, 
                     betSize, 
                     quarterPoolAllocation, 
                     finalPoolAllocation);
        
        address pAddr = address(p);
        PoolsByOrganizer[msg.sender] = pAddr; 
        numPools += 1;
    }
}