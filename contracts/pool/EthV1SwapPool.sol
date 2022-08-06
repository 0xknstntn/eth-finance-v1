/*
	@eth.finance
	@verison v1.0 
	@notice eth.finance Pool 
	@dev Konstantin Klyuchnikov
*/
pragma solidity >=0.8.0;

import "../interface/IERC20.sol";
import "../interface/TransferHelper.sol";
import "../interface/Math.sol";
import "../token/oToken.sol";
contract EthV1SwapPool {

	address private factory;

	address public token0;
	address public token1;
	address public lp;

	uint public k;
	uint private key = 0;
	uint public reserve0;
	uint public reserve1;
	uint public price0;
	uint public price1;
	uint public totalSupply;
	uint public fee;
	uint public constant min_liq = 10**2;

	bytes4 private constant TRANSFER_ACTION = bytes4(keccak256(bytes('_transfer(address,uint256)')));
	bytes4 private constant TRANSFERFROM_ACTION = bytes4(keccak256(bytes('_transferFrom(address,address,uint256)')));
	bytes4 private constant MINT_ACTION = bytes4(keccak256(bytes('mint(address,uint256)')));
	bytes4 private constant BURN_ACTION = bytes4(keccak256(bytes('burn(address,uint256)')));

	event AddLiquidity(address token0, address token1, address _to, uint amount);
	event DeleteLiquidity(address token0, address token1, address _to, uint liquidity);
	event SwapToken(address token0, address token1, address _to, uint amount0, uint amount1);
	event SyncStorage(address token0, address token1, uint newBalance0, uint newBalance1);

	constructor() {
		factory = msg.sender;
	}

	function createPool(address _token0, address _token1, uint _fee) public returns(bool){
		require(msg.sender == factory, 'NOT A FACTORY');
		token0 = _token0;
		token1 = _token1;
		fee = _fee;
		lp = address(new oToken(address(this)));
		return true;
	}

	function getBalancePool() private returns (uint balance0, uint balance1) {
		balance0 = reserve0;
		balance1 = reserve1;
	}

	function transfer(address to, address token, uint amount) private {
		(bool status, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_ACTION, to, amount));
        require(status && (data.length == 0 || abi.decode(data, (bool))), 'FAILED Transfer');
	}

	function transferFrom(address to, address token, uint amount) private {
		(bool status, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFERFROM_ACTION, to, amount));
        require(status && (data.length == 0 || abi.decode(data, (bool))), 'FAILED Transfer');
	}

    function mint(address lp, address to, uint amount) private {
		(bool status, bytes memory data) = lp.call(abi.encodeWithSelector(MINT_ACTION, to, amount));
        require(status && (data.length == 0 || abi.decode(data, (bool))), 'FAILED Mint');
	}

	function burn(address lp, address to, uint amount) private {
		(bool status, bytes memory data) = lp.call(abi.encodeWithSelector(BURN_ACTION, to, amount));
        require(status && (data.length == 0 || abi.decode(data, (bool))), 'FAILED Burn');
	}

	function _updateStorage(address _token0, address _token1, uint256 balanceContract0, uint256 balanceContract1) private {
		require((balanceContract0 >= 0) && (balanceContract1 >= 0), '0 number');
		if(balanceContract0 != 0 && balanceContract1 != 0) {
			price0 = (balanceContract1 * 1000000) / (balanceContract0);
			price1 = (balanceContract0 * 1000000) / (balanceContract1);
        } else if((balanceContract0 == 0) && (balanceContract1 == 0)) {
        	price0 = 0;
        	price1 = 0;
        }

        reserve0 = balanceContract0;
        reserve1 = balanceContract1;
        emit SyncStorage(_token0, _token1, reserve0, reserve1);
	}

	function updateK(address _token0, address _token1) private returns (uint) {
		uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
		if(key == 0) {
			k = balance0 * balance1;
			key = 1;
		}
		return k;
	}

	function _addLiquidity(address _token0, address _token1, address _to, uint amount) public returns (bool) {
		(uint balanceContract0, uint balanceContract1) = getBalancePool();
		require(_token0 == token0 && _token1 == token1, 'Not used address');
		//TransferHelper.safeTransferFrom(_token0, _to, address(this), amount0);
        //TransferHelper.safeTransferFrom(_token1, _to, address(this), amount1);
        IERC20(_token0).transferFrom(_to, address(this), amount);
        IERC20(_token1).transferFrom(_to, address(this), amount);

        uint _balance0 = IERC20(_token0).balanceOf(address(this));
	    uint _balance1 = IERC20(_token1).balanceOf(address(this));

        uint liquidity;
        if (totalSupply == 0) {
	        liquidity = Math.sqrt(((_balance0 - balanceContract0) * (_balance1 - balanceContract1)) - min_liq);
	        require(liquidity > 0, 'Minus liquidity');
	        mint(lp, _to, liquidity);
	        updateK(_token0, _token1);
	    } else {
	        liquidity = Math.min(((_balance0 - balanceContract0) * totalSupply) / balanceContract0, ((_balance1 - balanceContract1) * totalSupply) / balanceContract1);
	        require(liquidity > 0, 'Minus liquidity');
	        mint(lp, _to, liquidity);
	    }
	    totalSupply+=liquidity;
        _updateStorage(_token0, _token1, _balance0, _balance1);
        emit AddLiquidity(_token0, _token1, _to, amount);
        return true;
	}

	function _deleteLiquidity(address _token0, address _token1, address _to, uint _liquidity) public returns (bool) {
		(uint balanceContract0, uint balanceContract1) = getBalancePool();
		require(_token0 == token0 && _token1 == token1, 'Not used address');

	    uint amountDelLiq0 = (_liquidity * balanceContract0) / totalSupply;
	    uint amountDelLiq1 = (_liquidity * balanceContract1) / totalSupply;

	    require(amountDelLiq0 > 0 && amountDelLiq1 > 0, 'Minus amount');
	    burn(lp, _to, _liquidity);
	   	TransferHelper.safeTransferFrom(_token0, address(this), _to, amountDelLiq0);
	   	TransferHelper.safeTransferFrom(_token1, address(this), _to, amountDelLiq1);

	    totalSupply -= _liquidity;
	    uint newBalance0 = IERC20(_token0).balanceOf(address(this));
		uint newBalance1 = IERC20(_token1).balanceOf(address(this));
	    _updateStorage(_token0, _token1, newBalance0, newBalance1);
	    emit DeleteLiquidity(_token0, _token1, _to, _liquidity);
	    return true;
	}

	function _swap(address _token0, address _token1, address _to, uint amount0, uint amount1) public returns (bool) {
		(uint balanceContract0, uint balanceContract1) = getBalancePool();
		require(_token0 == token0 && _token1 == token1, 'Not used address');
		require(amount0 > 0 || amount1 > 0, 'Zero amount');
		require(amount0 == 0 || amount1 == 0, 'NST');
		require(_to != _token0 && _to != _token1, 'Not used address');
		uint fee_token0 = (amount0 * fee) / 1000;
		uint fee_token1 = (amount1 * fee) / 1000;
		if (amount0 > 0 && amount1 == 0) {
			IERC20(_token0).transferFrom(_to, address(this), ((amount0 + fee_token0)*price0) / 1000000);
        	IERC20(_token1).transferFrom(address(this), _to, amount0);
		}
        if (amount1 > 0 && amount0 == 0) {
        	IERC20(_token0).transferFrom(address(this), _to, amount1);
        	IERC20(_token1).transferFrom(_to, address(this), ((amount1 + fee_token1)*price1) / 1000000);
        }
        uint newBalance0 = IERC20(_token0).balanceOf(address(this));
		uint newBalance1 = IERC20(_token1).balanceOf(address(this));
	    _updateStorage(_token0, _token1, newBalance0, newBalance1);
        emit SwapToken(_token0, _token1, _to, amount0, amount1);
        return true;
	}

}
