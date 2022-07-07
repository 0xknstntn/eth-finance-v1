pragma solidity >=0.8.0;

interface IOndaV1LendingPoolFactory {
	function createLendingPool(address _stablecoin) external returns(address lendingPool);
	function getLendingPoolAddress(address _token0) external returns(address pool);
	event CreateLendingPool(address _stablecoin, address _lendingPool);
}