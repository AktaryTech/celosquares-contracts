pragma solidity ^0.7.6;

import "./Scoracle.sol"
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

contract Game is Context, Ownable, GeeksForGeeksRandom {
    // owner has special privileges
    address private _owner;
    
    address public charity;

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

    // this specifies what bet we're dealing with, whether it's the end score of a particular quarter or the whole game...
    // quarter4 should be a bigger prize 
    enum poolSize {
        default,
        quarter1,
        quarter2,
        quarter3,
        quarter4
    }

    poolSize public curr;
    
    function changePoolSize(poolSize input) public onlyOwner{
        curr = input;
    }

    

    constructor(address charityAddr, string memory firstTeam, string memory secondTeam, uint256 team1id, uint256 team2id, uint256 gameid, uint256 bet, uint256 quarter, uint final) {
        charity = charityAddr; 
        _owner = _msgSender();
        teamOne = firstTeam;
        teamTwo = secondTeam;
        teamOneid = team1id;
        teamTwoid = team2id;
        gameId = gameid; 
        betAmount = bet; 
        require(3*quarter + final == 1, "Need to set % of pool such that 3 x quarter + final = 1... we recommend 20% per quarter and 40% for the final pool");
        betForQuarter = quarter;
        betForFinal = final;
    }

    function placeBet(uint256 x, uint256 y) payable external {
        address bettor = _msgSender();
        require(betsPerPerson[bettor] < 10, "You can only place bets on 10 squares");
        require(Square[x][y].hasBet == false, "This square already has a bet placed");
        require(msg.value == betAmount, "Please send the proper amount to place a bet");
        board[x][y] = Square mySquare;
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
    function startGame() public onlyOwner {
        //can only be called once per game
        require(boardSet == false, "The board is already set");
        boardSet = true;
        
        for(int i = 0, i < 10; i++) {
            setSquare(i, rows, rowNums);
            setSquare(i, columns, columnNums);
        }

        for(int i = 0, i < 10; i++) {
            for(int j = 0, j < 10; j++) {
                Square needToSet = board[i][j];
                needToSet.firstTeamDigit = rows[i];
                needToSet.secondTeamDigit = columns[i];
                needToSet.isSet = true; 
            }
        }

        quarter1prize = prizePool * betForQuarter;
        quarter2prize = prizePool * betForQuarter;
        quarter3prize = prizePool * betForQuarter;
        quarter4prize = prizePool * betForFinal;
    }
    
    //TODO: add some way to read scoracle data and get legit scores
    Scoracle internal scoracle = new Scoracle();


    // takes raw team score, mod divides by 10 to get last digit
    // loops through all squares to find winner
    // pays based off whether it's a quarter or final score 
    function findAndPayWinner() {
        //gather gata from scoracle and get last digits
        (uint256 teamOneScore, uint256 teamTwoScore) = scoracle.getTeamsDataForQuarter(gameId, curr, teamOneid, teamTwoid);    
        uint teamOneLastDigit = teamOneScore % 10;
        uint teamTwoLastDigit = teamTwoScore % 10;
        
        //search for winner
        Square winner; 
        for(int i = 0, i < 10; i++) {
            for(int j = 0, j < 10; j ++) {
                sq = board[i][j];
                if (sq.firstTeamDigit == teamOneLastDigit && sq.secondTeamDigit == teamTwoLastDigit) {
                    winner = sq;
                    break;
                }
            }
        }
        
        uint256 prizeToSend;
        
        // set metadata and amount to send
        if(curr == quarter1) {
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
        else if (curr == quarter2) {
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
        else if (curr = quarter3) {
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