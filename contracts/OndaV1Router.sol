/*
	@org Onda.finance
	@verison v1.0 
	@notice Onda.finance Router 
	@dev Konstantin Klyuchnikov
*/


pragma solidity >=0.8.0;

import "./interface/IOndaV1Pool.sol";
import "./OndaV1Pool.sol";
import "./interface/IOndaV1Factory.sol";

contract OndaV1Router {
	address public factory;

	event SwapToken(address _token0, address _token1, uint _amount);
	event AddLiquidity(address _token0, address _token1, uint _amount);
	event DeleteLiquidity(address _token0, address _token1, uint _amountLiquidity);

	constructor(address _factory){
		factory = _factory;
	}

	function swapPriorityTokenToToken(address _token0, address _token1, uint _amount) public returns(bool) {
		address pool = IOndaV1Factory(factory).getPoolAddress(_token0, _token1);
		require(pool != address(0), 'Not exist pool');
		require(_amount > 0, 'Zero amount');
		IOndaV1Pool(pool)._swap(_token0, _token1, msg.sender, _amount, 0);
		emit SwapToken(_token0, _token1, _amount);
		return true;

	}
	function swapTokenToPriorityToken(address _token0, address _token1, uint _amount) public returns(bool) {
		address pool = IOndaV1Factory(factory).getPoolAddress(_token0, _token1);
		require(pool != address(0), 'Not exist pool');
		require(_amount > 0, 'Zero amount');
		IOndaV1Pool(pool)._swap(_token0, _token1, msg.sender, 0, _amount);
		emit SwapToken(_token0, _token1, _amount);
		return true;
	}

	function addLiquidity(address _token0, address _token1, uint _amount) public returns(bool){
		address pool = IOndaV1Factory(factory).getPoolAddress(_token0, _token1);
		require(pool != address(0), 'Not exist pool');
		require(_amount > 0, 'Zero amount');
		IOndaV1Pool(pool)._addLiquidity(_token0, _token1, msg.sender, _amount, _amount);
		emit AddLiquidity(_token0, _token1, _amount);
		return true;
	}
	function deleteLiquidity(address _token0, address _token1, uint _amountLiquidity) public returns(bool){
		address pool = IOndaV1Factory(factory).getPoolAddress(_token0, _token1);
		require(pool != address(0), 'Not exist pool');
		require(_amountLiquidity > 0, 'Zero amount');
		IOndaV1Pool(pool)._deleteLiquidity(_token0, _token1, msg.sender, _amountLiquidity);
		emit DeleteLiquidity(_token0, _token1, _amountLiquidity);
		return true;
	}
}