pragma solidity >=0.8.0;

interface IOndaV1SwapPoolFactory {
	function createPool(address _token0, address _token1, uint _fee) external view returns(address pair); 
	function getSwapPoolAddress(address _token0, address _token1) external view  returns(address pool);
	event CreatePool(address _token0, address _token1, address _pair, uint _fee);
}
