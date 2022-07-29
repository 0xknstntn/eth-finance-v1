/*
	@org Onda.finance
	@verison v1.0 
	@notice Onda.finance Factory 
	@dev Konstantin Klyuchnikov
*/

pragma solidity >=0.8.0;

import "../interface/IOndaV1LendingPool.sol";
import "../pool/OndaV1LendingPool.sol";
import "../periphery/OndaV1Router.sol";

contract OndaV1LendingPoolFactory {

	mapping(address => address) public lendingPoolAddress;

	address public creator;
	address public router;

	event CreateLendingPool(address _stablecoin, address _lendingPool);

	constructor() {
		creator = msg.sender;
	}

	function setRouter(address _router) public {
		require(msg.sender == creator, 'Not a createor');
		router = _router;
	}

	function createLendingPool(address _stablecoin) public returns(address lendingPool){
		require(router != address(0), 'Router not exist');
		require((_stablecoin != address(0)), 'Zero address');
		require(msg.sender == creator, 'Not a creator');
		address lendingPool = address(new OndaV1LendingPool());
		IOndaV1LendingPool(lendingPool).createLendingPool(_stablecoin, router);
		emit CreateLendingPool(_stablecoin, lendingPool);
		lendingPoolAddress[_stablecoin] = lendingPool;
		return lendingPool;
	}	

	function getLendingPoolAddress(address _token0) public returns(address){
		require(router != address(0), 'Router not exist');
		return lendingPoolAddress[_token0];
	}

}
