/*
	@org Onda.finance
	@verison v1.0 
	@notice Onda.finance Factory 
	@dev Konstantin Klyuchnikov
*/

pragma solidity >=0.8.0;

import "./interface/IOndaV1Pool.sol";
import "./OndaV1Pool.sol";


contract OndaV1Factory {

	mapping(address => mapping(address => address)) public poolAddress;

	event CreatePool(address _token0, address _token1, address _pair, uint _fee);

	function createPool(address _token0, address _token1, uint _fee) public returns(address pair){
		require(_token0 != _token1, 'Equal address');
		require((_token0 != address(0)) && (_token1 != address(0)), 'Zero address');
    		address pair = address(new OndaV1Pool());
    		IOndaV1Pool(pair).createPool(_token0, _token1, _fee);
    		emit CreatePool(_token0, _token1, pair, _fee);
    		poolAddress[_token0][_token1] = pair;
    		poolAddress[_token1][_token0] = pair;
    		return pair;
	}	

	function getPoolAddress(address _token0, address _token1) public returns(address pool){
		return poolAddress[_token0][_token1];
	}
}
