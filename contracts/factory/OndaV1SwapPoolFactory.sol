/*
	@org Onda.finance
	@verison v1.0 
	@notice Onda.finance Factory 
	@dev Konstantin Klyuchnikov
*/

pragma solidity >=0.8.0;

import "../interface/IOndaV1SwapPool.sol";
import "../pool/OndaV1SwapPool.sol";
import "../periphery/OndaV1Router.sol";

contract OndaV1SwapPoolFactory {

	mapping(address => mapping(address => address)) public poolAddress;
	mapping(address => mapping(address => address)) public lendingPoolAddress;

	address public creator;

	event CreatePool(address _token0, address _token1, address _pair, uint _fee);
	event CreateLendingPool(address _stablecoin, address _aToken, address _lendingPool);

	constructor() {
		creator = msg.sender;
	}

	function createSwapPool(address _token0, address _token1, uint _fee) public returns(address pair){
		require(_token0 != _token1, 'Equal address');
		require((_token0 != address(0)) && (_token1 != address(0)), 'Zero address');
    		address pair = address(new OndaV1SwapPool());
    		IOndaV1Pool(pair).createPool(_token0, _token1, _fee);
    		emit CreatePool(_token0, _token1, pair, _fee);
    		poolAddress[_token0][_token1] = pair;
    		poolAddress[_token1][_token0] = pair;
    		return pair;
	}

	function getSwapPoolAddress(address _token0, address _token1) public returns(address){
		return poolAddress[_token0][_token1];
	}
}
