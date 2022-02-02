pragma solidity ^0.5.16;
import "./Token.sol";
import "./factory.sol";
import "./libAmm.sol";
contract pair is ERCToken {
    
    using SafeMath for uint;
    using UQ112x112 for uint224;
    uint public constant MINIMUM_LIQUIDITY =10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));


    address public Factory;
    address public token0;
    address public token1;
    // address[] public tokens;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public Klast;

     constructor() public {
        Factory = msg.sender;
    }

    function getReserves() public view returns(uint112,uint112,uint32){
        return(reserve0,reserve1,blockTimestampLast);
    }

    function initialize(address _token0,address _token1) external{
    // require(msg.sender==factory);
    // for(uint i=0;i< _tokens.length;i++){
    //     tokens.push(_tokens[i]);
    // }
    token0 =_token0;
    token1 = _token1;

    }

    function _safeTransfer(address token,address to, uint value) public {
          // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))),'transfer Failed');
    }

    function gettokens( )view public returns(address,address){
        return(token0,token1);
    }

    function _update(uint balance0,uint balance1,uint112 _reserve0,uint112 _reserve1) public{
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1));
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeelapsed = blockTimestamp -blockTimestampLast;

        if(timeelapsed  >0 && _reserve0 !=0 && _reserve1!=0){
            // price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            // price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }

        reserve0 =uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;

    }


    function _mintFee(address feeTo,uint112 _reserve0,uint112 _reserve1)public returns(bool feeOn){

        // address feeTo =factory(_fact).feeTo(); 
        feeOn = feeTo != address(0);
        uint _kLast = Klast;
        if(feeOn){
            if(_kLast!=0){
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if(rootK>rootKLast){
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator/denominator;
                    if(liquidity>0){
                        _mint(feeTo,liquidity);
                    } 
                }
            }
    }
    }

    function _getbal(address _a)public  returns(uint256){
    return(ERCToken(_a).getbal(address(this)));
    }
    event mintcheck(uint112 r1,uint112 r2,uint balance0,uint balance1,uint amount0,uint amount1);
    function mint(address to,address feeTo) external returns(uint liquidity){
        (uint112 _reserve0,uint112 _reserve1,) = getReserves();
        uint balance0 = ERCToken(token0).getbal(address(this));
        uint balance1 = ERCToken(token1).getbal(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;
        emit mintcheck(_reserve0,_reserve1,balance0,balance1,amount0,amount1);
         bool feeOn =_mintFee(feeTo,_reserve0,_reserve1);
         uint _totalsupply = totalSupply;
        if(totalSupply ==0){
        liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
        _mint(address(0),MINIMUM_LIQUIDITY);
        }else{
            liquidity =Math.min(amount0.mul(_totalsupply)/_reserve0,amount1.mul(_totalsupply)/_reserve1);
        
        }
        require(liquidity >0);
        _mint(to,liquidity);
        _update(balance0,balance1,_reserve0,_reserve1);
        if(feeOn) Klast = uint(reserve0).mul(reserve1);
        return(liquidity);
    }

    function burn(address to,address feeTo) external returns(uint amount0,uint amount1){
        (uint112 _reserve0,uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        uint balance0 = ERCToken(token0).getbal(address(this));
        uint balance1 = ERCToken(token1).getbal(address(this));
        uint liquidity = balanceOf[address(this)];

         bool feeOn = _mintFee(feeTo,_reserve0,_reserve1);
        uint _totalsupply =totalSupply;
        amount0 = liquidity.mul(balance0) /_totalsupply;
        amount1 =liquidity.mul(balance1) /_totalsupply;
        require(amount0 >0 && amount1 >0);
        _burn(address(this),liquidity);
         _safeTransfer(_token0,to,amount0);
         _safeTransfer(_token1,to,amount1);
        balance0 = ERCToken(token0).balanceOf(address(this));
        balance1 = ERCToken(token1).balanceOf(address(this));
        _update(balance0,balance1,_reserve0,_reserve1);
        if(feeOn) Klast = uint(reserve0).mul(reserve1);   
    }

    function swap(uint amount0Out,uint amount1Out,address to)external{
        (uint112 _reserve0,uint112 _reserve1,) = getReserves();
        require(amount0Out >0 && amount1Out >0);
        require(amount0Out < _reserve0 && amount1Out < _reserve1);
        uint balance0;
        uint balance1;
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1);
         if(amount0Out >0) _safeTransfer(_token0,to,amount0Out);
         if(amount0Out >1) _safeTransfer(_token1,to,amount1Out);
        balance0 = ERCToken(token0).balanceOf(address(this));
        balance1 = ERCToken(token1).balanceOf(address(this));
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0);
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2));
    

        _update(balance0, balance1, _reserve0, _reserve1);
        // emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }


    


    




    
}