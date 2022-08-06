pragma solidity >=0.8.0;

interface IEthV1AddressProvider {
	function getLendingPoolFactoryAddress() external returns(address);
	function getSwapPoolFactoryAddress() external returns(address);
}
