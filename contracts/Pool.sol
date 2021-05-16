pragma solidity ^0.8.0;

import "./Scoracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// this generates a "random" number. if you call randMod(1000) it'll be between 0 and 9
// more info: https://www.geeksforgeeks.org/find-first-last-digits-number/
contract GeeksForGeeksRandom {
  
// Intializing the state variable
uint randNonce = 0;
  
// Defining a function to generate
// a random number
function randMod(uint _modulus) internal returns(uint) {
   // increase nonce
   randNonce++;  
   return uint(keccak256(abi.encodePacked(block.timestamp, 
                                          msg.sender, 
                                          randNonce))) % _modulus;
 }
}

contract Pool is Context, Ownable, GeeksForGeeksRandom {
    // **IMPORTANT** randomization is commented out for demo purposes
    
    // owner has special privileges
    address private _owner;
    
    address payable public charity;
    address public oracle; 

    // don't want the board numbers to be set more than once
    bool private boardSet; 

    uint256 public gameId;
    string public teamOne;
    uint256 public teamOneid;
    string public teamTwo;
    uint256 public teamTwoid; 
    uint256 public betAmount;
    uint256 public prizePool;
    
    
    // expressed as %, between 0 and 1 
    uint256 public betForQuarter;
    uint256 public betForFinal; 

    uint256 public quarter1Prize;
    bool public quarter1Paid;
    uint256 public quarter2Prize;
    bool public quarter2Paid;
    uint256 public quarter3Prize;
    bool public quarter3Paid;
    uint256 public quarter4Prize;
    bool public quarter4Paid;

    uint256[10] rows;
    // mapping (uint => bool) rowNums;

    uint256[10] columns;
    // mapping (uint => bool) columnNums;

    struct Meta {
        uint256 x;
        uint256 y;
    }

    mapping (address => uint) betsPerPerson;
    mapping(address => Meta[]) betMap; 
    // potentially add coord. pairs here to find winner easily? 

    struct Square {
        address bettor;
        bool hasBet; 
        bool isSet; 
        bool wonQuarter1;
        bool wonQuarter2;
        bool wonQuarter3;
        bool wonQuarter4;
        uint256 firstTeamDigit;
        uint256 secondTeamDigit; 
    }

    Square[10][10] board; 

    event PoolCreated(address _this, address _organizer);

    constructor(address scoracleAddr, address payable charityAddr, string memory firstTeam, string memory secondTeam, uint256 team1id, uint256 team2id, uint256 gameid, uint256 bet, uint256 quarter, uint fin) {
        oracle = scoracleAddr;
        charity = charityAddr; 
        _owner = msg.sender;
        teamOne = firstTeam;
        teamTwo = secondTeam;
        teamOneid = team1id;
        teamTwoid = team2id;
        gameId = gameid; 
        betAmount = bet; 
        require(3*quarter + fin == 1, "Need to set % of pool such that 3 x quarter + final = 1... we recommend 20% per quarter and 40% for the final pool");
        betForQuarter = quarter;
        betForFinal = fin;
        emit PoolCreated(address(this), _owner);
    }

    function placeBet(uint256 x, uint256 y) payable external {
        address payable bettor = payable(msg.sender);
        require(betsPerPerson[bettor] < 10, "You can only place bets on 10 squares");
        require(board[x][y].hasBet == false, "This square already has a bet placed");
        require(msg.value == betAmount, "Please send the proper amount to place a bet");
        Square memory mySquare;
        board[x][y] = mySquare;
        mySquare.bettor = bettor;
        mySquare.hasBet = true;
        betsPerPerson[bettor] += 1;
        Meta memory bet;
        bet.x = x;
        bet.y = y; 
        betMap[bettor].push(bet);
        prizePool += betAmount; 
    }

   // this uses the "random" number generate to create a random int between 0-9, and add it to the row/column, ensuring no redundancy
//    function setSquare(uint i, uint[10] storage arr, mapping(uint => bool) storage map) internal onlyOwner {
//         uint randNum = randMod(1000);
//         if (map[randNum] == false) {
//             map[randNum] = true;
//             arr[i] = randNum;
//         }
//         else {
//            setSquare(i, arr, map);
//         }
//     }
    
    // calls setSquare and puts numbers into arrays and maps, uses array to put into each Square struct
    // sets prize amounts
    function startGame() external onlyOwner {
        //can only be called once per game
        require(boardSet == false, "The board is already set");
        boardSet = true;
        
        for(uint i = 0; i < 10; i++) {
            // setSquare(i, rows, rowNums);
            // setSquare(i, columns, columnNums);
            rows[i] = i;
            columns[i] = i;
        }

        for(uint i = 0; i < 10; i++) {
            for(uint j = 0; j < 10; j++) {
                Square storage needToSet = board[i][j];
                needToSet.firstTeamDigit = rows[i];
                needToSet.secondTeamDigit = columns[i];
                needToSet.isSet = true; 
            }
        }

        quarter1Prize = prizePool * betForQuarter;
        quarter2Prize = prizePool * betForQuarter;
        quarter3Prize = prizePool * betForQuarter;
        quarter4Prize = prizePool * betForFinal;
    }
    
    Scoracle internal scoracle = Scoracle(oracle);


    // takes raw team score, mod divides by 10 to get last digit
    // loops through all squares to find winner
    // pays based off whether it's a quarter or final score 
    function getPaid(uint256 quarter) external {
        require( ((quarter == 1) || (quarter == 2) || (quarter == 3) || (quarter == 4)), "Not a valid quarter." );
        //gather gata from scoracle and get last digits
        (uint256 teamOneScore, uint256 teamTwoScore) = scoracle.getTeamsDataForQuarter(gameId, quarter, teamOneid, teamTwoid);    
        uint teamOneLastDigit = teamOneScore % 10;
        uint teamTwoLastDigit = teamTwoScore % 10;
        
        //search for winner
        Square memory winner; 
        for(uint i = 0; i < betsPerPerson[msg.sender]; i++) {
            Meta memory m = betMap[msg.sender][i];
            Square memory sq = board[m.x][m.y];
            if (sq.firstTeamDigit == teamOneLastDigit && sq.secondTeamDigit == teamTwoLastDigit) {
                    winner = sq;
                    break;
                }
        }
        
        uint256 prizeToSend;
        
        // set metadata and amount to send
        if(quarter == 1) {
            require(quarter1Paid == false, "You already paid out for Q1!");
            quarter1Paid = true; 
            winner.wonQuarter1 = true;
            prizeToSend = quarter1Prize;
            address payable dest = payable(winner.bettor);
            dest.transfer(prizeToSend);
            prizePool -= prizeToSend;
        }
        else if (quarter == 2) {
            require(quarter2Paid == false, "You already paid out for Q2!");
            quarter2Paid = true; 
            winner.wonQuarter2 = true;
            prizeToSend = quarter2Prize;
            address payable dest = payable(winner.bettor);
            dest.transfer(prizeToSend);
            prizePool -= prizeToSend;
        }
        else if (quarter == 3) {
            require(quarter3Paid == false, "You already paid out for Q3!");
            quarter3Paid = true; 
            winner.wonQuarter3 = true;
            prizeToSend = quarter3Prize;
            address payable dest = payable(winner.bettor);
            dest.transfer(prizeToSend);
            prizePool -= prizeToSend;
        }
        else {
            require(quarter4Paid == false, "You already paid out for Q4!");
            quarter4Paid = true; 
            winner.wonQuarter4 = true;
            prizeToSend = quarter4Prize;
            address payable dest = payable(winner.bettor);
            dest.transfer(prizeToSend);
            prizePool -= prizeToSend;
        }


    }

    function donateLostBetsToCharity() external onlyOwner {
        charity.transfer(prizePool);
    }

}