pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Scoracle is Ownable {

    event ScorePublished(
        uint256 indexed gameid, 
        uint256 indexed quarter,
        uint256 team1id, 
        uint256 team2id, 
        uint256 team1score, 
        uint256 team2score,
        uint timestamp
    );

    event UpcomingGameId(uint256 _gameid);

    struct Team {
        uint256 score;
    }

    struct GameID {
        uint gameid;
    }

    mapping(uint256 => mapping(uint256 => mapping(uint256 => Team))) public teamStatsForQuarter;

    uint256[] upcomingGameIds;

    mapping(uint256 => GameID) public gameids;

    constructor() public {}

    function setUpcomingGameId(uint256 _gameid) external {
        gameids[_gameid].gameid = _gameid;
        emit UpcomingGameId(_gameid);
    }

    /**
     * @dev - Call this function to send the data in the smart contract
     */
    function recordScore(uint256 _gameid, uint256 _quarter, uint256 _team1id, uint256 _team2id, uint256 _team1score, uint256 _team2score) external onlyOwner {
        require( ((_quarter == 1) || (_quarter == 2) || (_quarter == 3) || (_quarter == 4)), "Not a valid quarter." );

        if(_quarter > 1) {
            delete gameids[_gameid].gameid;
        }
        
        teamStatsForQuarter[_gameid][_quarter][_team1id].score = _team1score;
        teamStatsForQuarter[_gameid][_quarter][_team2id].score = _team2score;

        // emit ScorePublished event to log the timestamp at which the data enters the contract
        emit ScorePublished(
            _gameid, 
            _quarter,
            _team1id,
            _team2id, 
            teamStatsForQuarter[_gameid][_quarter][_team1id].score, 
            teamStatsForQuarter[_gameid][_quarter][_team2id].score, 
            block.timestamp
        );
    }

    function getTeamsDataForQuarter(uint256 _gameid, uint256 _quarter, uint256 _team1id, uint256 _team2id) internal view returns(uint256, uint256) {
        return ( 
            teamStatsForQuarter[_gameid][_quarter][_team1id].score, 
            teamStatsForQuarter[_gameid][_quarter][_team2id].score
        );
    }
    
    function clearGameData(uint256 _gameid, uint256 _team1id, uint256 _team2id) internal onlyOwner {
        for(uint i = 0; i < 4; i++) { 
            delete teamStatsForQuarter[_gameid][i][_team1id].score;
            delete teamStatsForQuarter[_gameid][i][_team2id].score;
        }
    }

}

