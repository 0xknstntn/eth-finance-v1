pragma solidity >=0.8.0;

contract OndaV1AddressProvider {
	address private lendingPoolFactory;
	address private swapPoolFactory;

	constructor(address _lendingPoolFactory, address _swapPoolFactory) {
		lendingPoolFactory = _lendingPoolFactory;
		swapPoolFactory = _swapPoolFactory;
	}

	function getLendingPoolFactoryAddress() public returns(address){
		return lendingPoolFactory;
	}

	function getSwapPoolFactoryAddress() public returns(address){
		return swapPoolFactory;
	}
}