pragma solidity >=0.8.0;

interface IOndaV1Pool {
	event AddLiquidity(address token0, address token1, address _to, uint amount);
	event DeleteLiquidity(address token0, address token1, address _to, uint liquidity);
	event SwapToken(address token0, address token1, address _to, uint amount0, uint amount1);
	event SyncStorage(address token0, address token1, uint newBalance0, uint newBalance1);

	function createPool(address _token0, address _token1, uint _fee) external returns(bool);
	function _addLiquidity(address _token0, address _token1, address _to, uint amount) external returns (bool);
	function _deleteLiquidity(address _token0, address _token1, address _to, uint _liquidity) external returns (bool);
	function _swap(address _token0, address _token1, address _to, uint amount0, uint amount1) external returns (bool);
}