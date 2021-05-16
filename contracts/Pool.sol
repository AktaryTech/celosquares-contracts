pragma solidity ^0.7.6;

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
   return uint(keccak256(abi.encodePacked(now, 
                                          msg.sender, 
                                          randNonce))) % _modulus;
 }
}

contract Pool is Context, Ownable, GeeksForGeeksRandom {
    // owner has special privileges
    address private _owner;
    
    address public charity;
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
    mapping (uint => bool) rowNums;

    uint256[10] columns;
    mapping (uint => bool) columnNums;

    mapping (address => uint) betsPerPerson;

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

    event MetaData(address _this, address _organizer);

    constructor(address scoracleAddr, address charityAddr, string memory firstTeam, string memory secondTeam, uint256 team1id, uint256 team2id, uint256 gameid, uint256 bet, uint256 quarter, uint fin) {
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
        emit MetaData(address(this), _owner);
    }

    function placeBet(uint256 x, uint256 y) payable external {
        address bettor = msg.sender;
        require(betsPerPerson[bettor] < 10, "You can only place bets on 10 squares");
        require(Square[x][y].hasBet == false, "This square already has a bet placed");
        require(msg.value == betAmount, "Please send the proper amount to place a bet");
        Square mySquare;
        board[x][y] = mySquare;
        mySquare.bettor = bettor;
        mySquare.hasBet = true;
        betsPerPerson[bettor] += 1;
        prizePool += betAmount; 
    }

   // this uses the "random" number generate to create a random int between 0-9, and add it to the row/column, ensuring no redundancy
   function setSquare(uint i, uint[] arr, mapping(uint => bool) map) internal onlyOwner {
        uint randNum = randMod(1000);
        if (map[randNum] == false) {
            map[randNum] = true;
            arr[i] = randNum;
        }
        else {
            setSquare(i);
        }
    }
    
    // calls setSquare and puts numbers into arrays and maps, uses array to put into each Square struct
    // sets prize amounts
    function startGame() external onlyOwner {
        //can only be called once per game
        require(boardSet == false, "The board is already set");
        boardSet = true;
        
        for(int i = 0; i < 10; i++) {
            setSquare(i, rows, rowNums);
            setSquare(i, columns, columnNums);
        }

        for(int i = 0; i < 10; i++) {
            for(int j = 0; j < 10; j++) {
                Square needToSet = board[i][j];
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
    function findAndPayWinner(uint256 quarter) external onlyOwner {
        //gather gata from scoracle and get last digits
        (uint256 teamOneScore, uint256 teamTwoScore) = scoracle.getTeamsDataForQuarter(gameId, curr, teamOneid, teamTwoid);    
        uint teamOneLastDigit = teamOneScore % 10;
        uint teamTwoLastDigit = teamTwoScore % 10;
        
        //search for winner
        Square winner; 
        bool hasWinner;
        for(int i = 0; i < 10; i++) {
            for(int j = 0; j < 10; j ++) {
                Square sq;
                sq = board[i][j];
                if (sq.firstTeamDigit == teamOneLastDigit && sq.secondTeamDigit == teamTwoLastDigit) {
                    winner = sq;
                    hasWinner = true;
                    break;
                }
            }
            
            if (hasWinner) {
                break;
            }

        }
        
        uint256 prizeToSend;
        
        // set metadata and amount to send
        if(quarter == 1) {
            require(quarter1Paid, "You already paid out for Q1!");
            quarter1Paid = true; 
            winner.wonQuarter1 = true;
            prizeToSend = quarter1Prize;
            if(winner.hasbet) {
                address dest = winner.bettor;
                dest.transfer(prizeToSend);
            }
            else{
                quarter2prize += quarter1Prize * .25;
                quarter3prize += quarter1Prize * .25;
                quarter4prize += quarter1Prize * .5;
            }
        }
        else if (quarter == 2) {
            require(quarter2Paid, "You already paid out for Q2!");
            quarter2Paid = true; 
            winner.wonQuarter2 = true;
            prizeToSend = quarter2Prize;
            if(winner.hasbet) {
                address dest = winner.bettor;
                dest.transfer(prizeToSend);
            }
            else{
                quarter3prize += quarter2Prize * .25;
                quarter4prize += quarter2Prize * .75;
            }
        }
        else if (quarter == 3) {
            require(quarter3Paid, "You already paid out for Q3!");
            quarter3Paid = true; 
            winner.wonQuarter3 = true;
            prizeToSend = quarter3Prize;
            if(winner.hasbet) {
                address dest = winner.bettor;
                dest.transfer(prizeToSend);
            }
            else{
                quarter4prize += quarter3Prize;
            }
        }
        else {
            require(quarter4Paid, "You already paid out for Q4!");
            quarter4Paid = true; 
            winner.wonQuarter4 = true;
            prizeToSend = quarter4Prize;
            if(winner.hasbet) {
                address dest = winner.bettor;
                dest.transfer(prizeToSend);
            }
            else{
                charity.transfer(prizeToSend);
            }
        }

    }

}