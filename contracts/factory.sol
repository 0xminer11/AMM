
pragma solidity ^0.5.16;
import "./libAmm.sol";
import "./factory.sol";
import "./pair.sol";
// import "./libraryamm.sol";
contract factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address[] memory _tokens) public {
        
        for(uint i=0;i<_tokens.length;i++){
            for(uint j=i+1;j<_tokens.length;j++){
                require(_tokens[i]!=_tokens[j]);
            }
        }

        for(uint i=0;i<_tokens.length;i++){
            for(uint j=0;j<_tokens.length;j++){
                if(getPair[_tokens[i]][_tokens[j]] == address(0) && _tokens[i]!=_tokens[j]){
                    creatingpair(_tokens[i],_tokens[j]);
                }
                
            }
        }
         
    }
    
        function creatingpair(address tokenA, address tokenB) public returns (address pairadd) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0)); 
        bytes memory bytecode = type(pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pairadd := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        pair(pairadd).initialize(token0, token1);
        getPair[token0][token1] = pairadd;
        getPair[token1][token0] = pairadd; 
        allPairs.push(pairadd);
        
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }
    
    function gettoken(address pairadd) view public returns (address ,address){
        (address token0,address token1)= pair(pairadd).gettokens();
        return(token0,token1);
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    function getReserves(address pairadd) public view returns(uint112 reserve0,uint112 reserve1){
        (uint112 _reserve0,uint112 _reserve1,)=pair(pairadd).getReserves();
        return(_reserve0,_reserve1);
    }

    function _safeTransfer(address token,address to, uint value) public returns(bool){
        ERCToken t =ERCToken(token);
        t.transfer(to,value);
        return(true);    
    } 

    function _mintliquidity(address to,address tokenA,address tokenB) public returns(uint){
        address _pair =getPair[tokenA][tokenB];
        return(pair(_pair).mint(to,feeTo));
    }  

    function _burn(address to) public{
        pair(msg.sender).burn(to,feeTo);
    }
}