// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//distribute profit by manager
//user can withdraw after lock time without profit.
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
 
    // token to ETH 
    /*
    function swapExactTokensForETH( 
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint  amounts);
*/

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)    external    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)   external    returns (uint[] memory amounts);
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

//polygon
//sushiswap router:0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 
//quickswap router:0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
//dai:0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
//usdt:0xc2132D05D31c914a87C6611C10748AEb04B58e8F
//bnb:0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3
//shiba:0x6f8a06447Ff6FcF75d803135a7de15CE88C1d4ec
//avax:0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b
address[] public AllowTokens=[0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,0xc2132D05D31c914a87C6611C10748AEb04B58e8F,
0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3,0x6f8a06447Ff6FcF75d803135a7de15CE88C1d4ec,
0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b];
//address  public WETH=0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
 


//binance 
//pancakeswap router:0x10ED43C718714eb63d5aA57B78B54704E256024E
//dai:0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3
//eth:0x2170Ed0880ac9A755fd29B2688956BD959F933F8
//usdc:0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d
//matic:0xCC42724C6683B7E57334c4E856f4c9965ED682bD
//doge:0xbA2aE424d960c26247Dd6c32edC70B295c744C43
//dot:0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402
//ltc:0x4338665CBB7B2485A8855A139b75D5e34AB0DB94
//shiba:0x2859e4544C4bB03966803b044A93563Bd2D0DD4D
//avax:0x1CE0c2827e2eF14D5C4f29a091d735A204794041
//babydoge:0xc748673057861a797275CD8A068AbB95A902e8de

/*
address[] public AllowTokens=[0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3,0x2170Ed0880ac9A755fd29B2688956BD959F933F8,
0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d,0xCC42724C6683B7E57334c4E856f4c9965ED682bD,
0xbA2aE424d960c26247Dd6c32edC70B295c744C43,0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402,
0x4338665CBB7B2485A8855A139b75D5e34AB0DB94,0x2859e4544C4bB03966803b044A93563Bd2D0DD4D,
0x1CE0c2827e2eF14D5C4f29a091d735A204794041,0xc748673057861a797275CD8A068AbB95A902e8de];
*/

 
mapping(address => bool) public TokenMap; // default value for each key is false

uint public LockTimeDays=3;

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

LockTime[msg.sender]=block.timestamp + LockTimeDays * 1 minutes;

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





//only send profit except capital
function DistributeProfit( ) external  onlyOwner{
    uint TotalProfit=USDToken.balanceOf(address(this)) - PoolBalance;
    require(TotalProfit > MinProfit, "No profit");
    
    for (uint i; i < UserCount; i++) { 
        require(Users[i].InvestAmount > 0,"user have no invest.");
        uint  CapitalAndProfit= Users[i].InvestAmount *  USDToken.balanceOf(address(this)) / totalSupply() ; 
        require(CapitalAndProfit > Users[i].InvestAmount,"Capital And Profit need > user Invest Amount");
        
        uint profit=CapitalAndProfit - Users[i].InvestAmount;
        uint Fee=(FeePercent * profit) / 100 ;
        uint UserProfit=profit - Fee;

        //send profit
        USDToken.transfer(Users[i].UserAddress, UserProfit);
        //Users[i].InvestAmount=0;

        //send fee
        USDToken.transfer(msg.sender, Fee);

    }

if (USDToken.balanceOf(address(this)) > 0 ){
USDToken.transfer(msg.sender, USDToken.balanceOf(address(this)));
}
//PoolBalance =USDToken.balanceOf(address(this));



}

function ShowProfit(address _user) public view returns (uint) {
    uint profit =  Users[Userid[_user]].InvestAmount * USDToken.balanceOf(address(this)) / totalSupply() ; 
    uint Fee=(FeePercent * profit) / 100 ;
    uint UserProfit=profit - Fee;
    return  UserProfit;

}

function ShowARR() public view returns (uint) { 
    require(USDToken.balanceOf(address(this)) > PoolBalance ,"err");
    return     ((USDToken.balanceOf(address(this)) -  PoolBalance ) / PoolBalance )*100;

}


function Swap(
    address Router, address FromTokenAddress, 
    address ToTokenAddress,uint TradeAmount
    ) external  onlyOwner {

//require( CheckAllowToken( FromTokenAddress) && CheckAllowToken( ToTokenAddress), "This token is not allow.");

 //  require(TradeAmount<=IERC20(FromTokenAddress).balanceOf(address(this)), "Token on contract is not enough");
   TokenToETHtoTokenV2(Router,TradeAmount, 1,FromTokenAddress,ToTokenAddress);
}

/*
function TokenToTokenV2(address _RouterAddress, uint256 amountIn, 
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
*/
function TokenToETHtoTokenV2(address _RouterAddress, uint amountIn, 
    uint amountOutMin ,address FromTokenAddress,address ToTokenAddress) public onlyOwner {
 
require( CheckAllowToken( FromTokenAddress) && CheckAllowToken( ToTokenAddress), "This token is not allow.");

require(amountIn<=IERC20(FromTokenAddress).balanceOf(address(this)), "Token on contract is not enough");
 
    IERC20(FromTokenAddress).approve(_RouterAddress, type(uint256).max);
    
    uint deadline = block.timestamp + 500; 

    IUniswapV2Router02    Router = IUniswapV2Router02(_RouterAddress);
    

               // swap the ERC20 token for ETH
uint ethFromSwap = Router.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                _getPath(FromTokenAddress,Router.WETH()),
                address(this),
                deadline
            )[1];

uint tokenAmount = Router.swapExactETHForTokens{value: ethFromSwap}(
            amountOutMin,
            _getPath(Router.WETH(),ToTokenAddress),
            address(this),
            deadline
        )[1];

 /*

 // make the swap
        Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin, // accept any amount of ETH
            _getPath(FromTokenAddress,WETH),
            address(this),
            block.timestamp
        );




    Router.swapExactTokensForTokens(
        amountIn,
        amountOutMin,
        _getPath(FromTokenAddress,ToTokenAddress),
        address(this),
        deadline
        );

        */
}

function _getPath(address a,address b) public pure returns (address[] memory) {
    
    address[] memory path = new address[](2);
    path[0] = a;
    path[1] = b;
    
    return path;
}


function CheckAllowToken(address _TokenAddress) public view returns (bool) {
    for (uint i = 0; i < AllowTokens.length; i++) {
        if (AllowTokens[i] == _TokenAddress) {
            return true;
        }
    }

    return false;
}

/*
function AddToken(address _TokenAddress) public onlyOwner {
    AllowTokens.push(_TokenAddress);
    TokenMap[_TokenAddress] = true;
 
}
*/

   
  receive() payable external {}
    //(20 * 600) / 100 = 120  <->  600 * 20%
}
