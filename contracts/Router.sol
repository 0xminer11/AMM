pragma solidity ^0.5.16;
import "./libAmm.sol";
import "./factory.sol";
import "./pair.sol";
contract router{

using SafeMath for uint;

address public  Factory;
address public WETH;

constructor(address _factory) public {
    Factory = _factory;
    // WETH = _WETH;
}
function pairFor(address _Factory, address tokenA, address tokenB) public pure returns (address pair) {
        (address token0, address token1) = (tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                _Factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

function _addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin, address to) public returns(uint amountA,uint amountB,uint liquidity){
    if(factory(Factory).getPair(tokenA,tokenB) == address(0)){
        factory(Factory).creatingpair(tokenA,tokenB);
    }
    address pairadd=factory(Factory).getPair(tokenA,tokenB);
    (uint reserveA,uint reserveB) = factory(Factory).getReserves(pairadd);
    if(reserveA ==0 && reserveB ==0){
        (amountA,amountB) =(amountADesired,amountBDesired);
    }else{
        uint Bopt =amountADesired.mul(reserveB)/reserveA;
        if(Bopt <= amountADesired){ 
            require(Bopt >=amountBMin);
            (amountA,amountB) =(amountADesired,Bopt);
        }else{
            uint Aopt = amountBDesired.mul(reserveA)/reserveB;
            if(Aopt <amountADesired){
                require(Aopt>=amountAMin);
                (amountA,amountB) =(Aopt,amountBDesired);
            }
        }
    }
    liquidity = factory(Factory)._mintliquidity(to,tokenA,tokenB);
    return(amountA,amountB,liquidity);


}
event process(bool successA,bool suceessB,address pairadd);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB,liquidity) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin,to);
        address factpairadd = pairFor(Factory, tokenA, tokenB);
        (bool successA)=factory(Factory)._safeTransfer(tokenA,factpairadd,amountA);
        (bool successB)=factory(Factory)._safeTransfer(tokenB,factpairadd,amountB);
        // (bool successA, )=tokenA.call(abi.encodeWithSignature("transfer(address,uint)", factpairadd, amountA));
        // (bool suceessB, )=tokenB.call(abi.encodeWithSignature("transfer(address,uint)", factpairadd, amountB));
    //     // TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);  
         emit process(successA,successB,factpairadd);
     return(amountA,amountB,liquidity);
    }

    // function getLiquidity(address pairadd,address to) public returns(uint){
    // return(pair(pairadd).mint(to));
    // }

    function gettoken(address pairadd) view public returns (address ,address){
        (address token0,address token1)= pair(pairadd).gettokens();
        return(token0,token1);
    }


}