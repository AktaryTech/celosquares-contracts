pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Scoracle is Ownable {

    enum Quarter { FIRST, SECOND, THIRD, FOURTH }

    struct Team {
        uint256 gameID;
        uint256 teamID;
        uint256 score;
        uint256 quarter;
    }

    mapping(uint256 => mapping(uint256 => Team)) public teamStatsForQuarter;

    event ScorePublished(
        uint256 indexed gameid, 
        uint256 indexed quarter,
        uint256 team1id, 
        uint256 team2id, 
        uint256 team1score, 
        uint256 team2score,
        uint timestamp
    );

    constructor() public {}

    /**
     * @dev - Call this function to send the data in the smart contract
     */
    function response(uint256 _gameid, uint256 _quarter, uint256 _team1id, uint256 _team2id, uint256 _team1score, uint256 _team2score) external onlyOwner {

        // set team 1 stats for Quarter
        teamStatsForQuarter[_quarter][_team1id].gameID = _gameid;
        teamStatsForQuarter[_quarter][_team1id].quarter = _quarter;
        teamStatsForQuarter[_quarter][_team1id].teamID = _team1id;
        teamStatsForQuarter[_quarter][_team1id].score = _team1score;

        // set team 2 stats for Quarter
        teamStatsForQuarter[_quarter][_team2id].gameID = _gameid;
        teamStatsForQuarter[_quarter][_team2id].quarter = _quarter;
        teamStatsForQuarter[_quarter][_team2id].teamID = _team2id;
        teamStatsForQuarter[_quarter][_team2id].score = _team2score;

        // emit ScorePublished event to log the timestamp at which the data enters the contract
        emit ScorePublished(
            _gameid, 
            _quarter, 
            teamStatsForQuarter[_quarter][_team1id].quarter, 
            teamStatsForQuarter[_quarter][_team2id].teamID, 
            teamStatsForQuarter[_quarter][_team1id].score, 
            teamStatsForQuarter[_quarter][_team2id].score, 
            block.timestamp
        );
    }

    function getTeamDataForQuarter(uint256 _quarter, uint256 _teamid) internal view returns(uint256, uint256, uint256) {
        return (
            teamStatsForQuarter[_quarter][ _teamid].gameID, 
            teamStatsForQuarter[_quarter][ _teamid].teamID, 
            teamStatsForQuarter[_quarter][ _teamid].score
        );
    }

    function getTeamsDataForQuarter(uint256 _quarter, uint256 _team1id, uint256 _team2id) internal view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            teamStatsForQuarter[_quarter][ _team1id].gameID, 
            teamStatsForQuarter[_quarter][ _team1id].teamID, 
            teamStatsForQuarter[_quarter][ _team1id].score,
            teamStatsForQuarter[_quarter][ _team2id].gameID, 
            teamStatsForQuarter[_quarter][ _team2id].teamID, 
            teamStatsForQuarter[_quarter][ _team2id].score
        );
    }

}

