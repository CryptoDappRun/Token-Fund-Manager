// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//distribute profit by manager
//withdraw after lock time.
//withdraw dont recieve profit, and contract have enough USDT to withdraw
//need token with 18 decimals.
//DAI:0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
//USDT:0xc2132D05D31c914a87C6611C10748AEb04B58e8F
//deployed 
//polygon 


//execution reverted: UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT",
// maybe your swap amount too small

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}


contract Fund is ERC20, Ownable {
    event Deposit(address, uint);
    event WithdrawEvent(address, uint);


    mapping(address => uint) LockTime;
    bool public locked = false;

  // SushiSwap
  //IUniswapV2Router02 private constant sushiRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  address public sushiRouterAddress=0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    struct UserInfo {
        uint orderID;
        address payable UserAddress;
        uint InvestAmount;

    }
    mapping(uint256 => UserInfo) public Users;
    mapping(address => uint) public Userid;

   address[] public AllowTokens=[0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,0xc2132D05D31c914a87C6611C10748AEb04B58e8F];
 


 //uint public LockTimeDays;

    uint public UserCount;
    uint public MinProfit=100;
    uint public  FeePercent = 5;
    uint public PoolBalance;





    ERC20 public USDToken ;
    
    address ContractOwner;

    modifier noReentrant() {
      require(!locked, "No re-entrancy");
      locked = true;
      _;
      locked = false;
  }



  constructor(address _USD) ERC20("Fund", "FUND") {
    USDToken=ERC20(_USD);
  //  _mint(msg.sender, initialSupply);
    ContractOwner=msg.sender;
}

function depositUSDToken (uint256 amount) public noReentrant{
    // Increment the account balance for this address
    
    require(amount > 0, "You need to sell at least some tokens");
    uint256 allowance = USDToken.allowance(msg.sender, address(this));
    require(allowance >= amount, "Check the token allowance");

//user transfer USD to contract
USDToken.transferFrom(msg.sender, address(this), amount);

//contract mint contract token to user.
_mint(msg.sender, amount);       // minting same amount of tokens to for simplicity

bool InvestorExist=false;
for (uint i; i < UserCount; i++) {
   if (Users[i].UserAddress == msg.sender){
       Users[i].InvestAmount += amount;
       InvestorExist=true;
   }
}

if (!InvestorExist){
    Userid[msg.sender]=UserCount;
    Users[UserCount].InvestAmount += amount;
    Users[UserCount].UserAddress =payable (msg.sender) ;
}

LockTime[msg.sender]=block.timestamp + 3 minutes;

PoolBalance += amount;
UserCount++;
    // Trigger an event for this deposit
    //emit DepositEvent(from, tokens);
}



function Withdraw() external noReentrant{
    uint _shares = Users[Userid[msg.sender]].InvestAmount;
    require(USDToken.balanceOf(address(this)) >= _shares, "farm balance is insufficient");
    require(block.timestamp > LockTime[msg.sender], "you can withdraw after your lock time.");        
    require(_shares > 0, "your investment is zero");
    _burn( msg.sender, _shares);
    USDToken.transfer(msg.sender, _shares);
    Users[Userid[msg.sender]].InvestAmount=0;


require(PoolBalance >= _shares, "PoolBalance >= _shares");

//update pool
    PoolBalance -=_shares;
    emit WithdrawEvent(msg.sender, _shares);
}






function DistributeProfit( ) external  onlyOwner{
    uint TotalProfit=USDToken.balanceOf(address(this)) - PoolBalance;
    require(TotalProfit > MinProfit, "No profit");
    
    for (uint i; i < UserCount; i++) { 
        require(Users[UserCount].InvestAmount > 0,"user have no invest.");
        uint  profit= Users[UserCount].InvestAmount *  USDToken.balanceOf(address(this)) / totalSupply() ; 
        uint Fee=(FeePercent * profit) / 100 ;
        uint UserProfit=profit - Fee;

        USDToken.transfer(Users[UserCount].UserAddress, UserProfit);

    }


}

function ShowProfit(address _user) public view returns (uint) {
    uint profit =  Users[Userid[_user]].InvestAmount * USDToken.balanceOf(address(this)) / totalSupply() ; 
    uint Fee=(5 * profit) / 100 ;
    uint UserProfit=profit - Fee;
    return  UserProfit;

}

function ShowARR() public view returns (uint) { 
    require(USDToken.balanceOf(address(this)) > PoolBalance ,"err");
   return     ((USDToken.balanceOf(address(this)) -  PoolBalance ) / PoolBalance )*1000;

}


function Swap(
    address Router, address FromTokenAddress, 
    address ToTokenAddress,uint TradeAmount
    ) external  onlyOwner {

     require(TradeAmount<=IERC20(FromTokenAddress).balanceOf(address(this)), "Token on contract is not enough");
      _TokenToTokenV2(Router,TradeAmount, 1,FromTokenAddress,ToTokenAddress);
}


function _TokenToTokenV2(address _RouterAddress, uint256 amountIn, 
uint256 amountOutMin ,address FromTokenAddress,address ToTokenAddress) public {
   
IERC20(FromTokenAddress).approve(_RouterAddress, type(uint256).max);
 
uint256 deadline = block.timestamp + 300; 

   IUniswapV2Router02    Router = IUniswapV2Router02(_RouterAddress);
  
    Router.swapExactTokensForTokens(
        amountIn,
        amountOutMin,
        _getPath(FromTokenAddress,ToTokenAddress),
        address(this),
        deadline
    );
}
function _getPath(address a,address b) public pure returns (address[] memory) {
    
    address[] memory path = new address[](2);
    path[0] = a;
    path[1] = b;
    
    return path;
}
    //(20 * 600) / 100 = 120  <->  600 * 20%
}