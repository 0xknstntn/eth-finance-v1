/*
	@org eth.finance
	@verison v1.0 
	@notice eth.finance Router 
	@dev Konstantin Klyuchnikov
*/


pragma solidity >=0.8.0;

import "../interface/IEthV1SwapPool.sol";
import "../interface/IEthV1LendingPool.sol";
import "../interface/IEthV1SwapPoolFactory.sol";
import "../interface/IEthV1LendingPoolFactory.sol";
import "../interface/IEthV1AddressProvider.sol";

contract EthV1Router {
	address public provider;
	//SwapPool event
	event SwapToken(address _token0, address _token1, uint _amount);
	event AddLiquidity(address _token0, address _token1, uint _amount);
	event DeleteLiquidity(address _token0, address _token1, uint _amountLiquidity);
	
	//Lending pool event
	event AddLend(address _stablecoin, address _aToken, uint _amount);
	event DeleteLend(address _stablecoin, address _aToken, uint _amount);
	event NewBorrow(address _stablecoin, address _aToken, uint _amount);
	event DeleteBorrow(address _stablecoin, address _aToken, uint _amount);

	constructor(address _provider){
		provider = _provider;
	}

	function swapPriorityTokenToToken(address _token0, address _token1, uint _amount) public returns(bool) {
		address factory = IEthV1AddressProvider(provider).getSwapPoolFactoryAddress();
		address pool = IEthV1SwapPoolFactory(factory).getSwapPoolAddress(_token0, _token1);
		require(pool != address(0), 'Not exist pool');
		require(_amount > 0, 'Zero amount');
		IEthV1Pool(pool)._swap(_token0, _token1, address(msg.sender), _amount, 0);
		emit SwapToken(_token0, _token1, _amount);
		return true;
	}

	function swapTokenToPriorityToken(address _token0, address _token1, uint _amount) public returns(bool) {
		address factory = IEthV1AddressProvider(provider).getSwapPoolFactoryAddress();
		address pool = IEthV1SwapPoolFactory(factory).getSwapPoolAddress(_token0, _token1);
		require(pool != address(0), 'Not exist pool');
		require(_amount > 0, 'Zero amount');
		IEthV1Pool(pool)._swap(_token0, _token1, msg.sender, 0, _amount);
		emit SwapToken(_token0, _token1, _amount);
		return true;
	}

	function addLiquidity(address _token0, address _token1, uint _amount) public returns(bool){
		address factory = IEthV1AddressProvider(provider).getSwapPoolFactoryAddress();
		address pool = IEthV1SwapPoolFactory(factory).getSwapPoolAddress(_token0, _token1);
		require(pool != address(0), 'Not exist pool');
		require(_amount > 0, 'Zero amount');
		address _to = msg.sender;
		IEthV1Pool(pool)._addLiquidity(_token0, _token1, _to, _amount);
		emit AddLiquidity(_token0, _token1, _amount);
		return true;
	}

	function deleteLiquidity(address _token0, address _token1, uint _amountLiquidity) public returns(bool){
		address factory = IEthV1AddressProvider(provider).getSwapPoolFactoryAddress();
		address pool = IEthV1SwapPoolFactory(factory).getSwapPoolAddress(_token0, _token1);
		require(pool != address(0), 'Not exist pool');
		require(_amountLiquidity > 0, 'Zero amount');
		IEthV1Pool(pool)._deleteLiquidity(_token0, _token1, address(msg.sender), _amountLiquidity);
		emit DeleteLiquidity(_token0, _token1, _amountLiquidity);
		return true;
	}

	function addLend(address _stablecoin, address _aToken, uint _amount) public returns(bool){
		address factory = IEthV1AddressProvider(provider).getLendingPoolFactoryAddress();
		address lendingPool = IEthV1LendingPoolFactory(factory).getLendingPoolAddress(_stablecoin);
		require(lendingPool != address(0), 'Not exist pool');
		require(_amount > 0, 'Zero amount');
		IEthV1LendingPool(lendingPool)._addLend(_stablecoin, _aToken, address(msg.sender), _amount);
		emit AddLend(_stablecoin, _aToken, _amount);
		return true;
	}

	function deleteLend(address _stablecoin, address _aToken, uint _amount) public returns(bool){
		address factory = IEthV1AddressProvider(provider).getLendingPoolFactoryAddress();
		address lendingPool = IEthV1LendingPoolFactory(factory).getLendingPoolAddress(_stablecoin);
		require(lendingPool != address(0), 'Not exist pool');
		require(_amount > 0, 'Zero amount');
		IEthV1LendingPool(lendingPool)._deleteLend(_stablecoin, _aToken, address(msg.sender), _amount);
		emit DeleteLend(_stablecoin, _aToken, _amount);
		return true;
	}

	function newBorrow(address _stablecoin, address _aToken, uint _amount) payable public returns(bool){
		address factory = IEthV1AddressProvider(provider).getLendingPoolFactoryAddress();
		address lendingPool = IEthV1LendingPoolFactory(factory).getLendingPoolAddress(_stablecoin);
		require(lendingPool != address(0), 'Not exist pool');
		require(_amount > 0, 'Zero amount');
		require(msg.value > 0, 'Zero msg.value');
		require(((msg.value * 80)/100) == ((_amount / 100) * 100000000000000000), 'Wrong _amount');
		IEthV1LendingPool(lendingPool)._newBorrow(_stablecoin, _aToken, address(msg.sender), _amount, msg.value);
		payable(lendingPool).send(msg.value);
		emit NewBorrow(_stablecoin, _aToken, _amount);
		return true;
	}

	function deleteBorrow(address _stablecoin, address _aToken, uint _amount) public returns(bool){
		address factory = IEthV1AddressProvider(provider).getLendingPoolFactoryAddress();
		address lendingPool = IEthV1LendingPoolFactory(factory).getLendingPoolAddress(_stablecoin);
		require(lendingPool != address(0), 'Not exist pool');
		require(_amount > 0, 'Zero amount');
		IEthV1LendingPool(lendingPool)._deleteBorrow(_stablecoin, _aToken, payable(address(msg.sender)), _amount);
		emit DeleteBorrow(_stablecoin, _aToken, _amount);
		return true;
	}
}
