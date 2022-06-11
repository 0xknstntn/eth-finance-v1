pragma solidity >=0.8.0;

import "./interface/IERC20.sol";
import "./interface/TransferHelper.sol";
import "./interface/Math.sol";


contract Pair {

	address owner;

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
	uint public constant min_liq = 10**2;

	bytes4 private constant TRANSFER_ACTION = bytes4(keccak256(bytes('_transfer(address,uint256)')));
	bytes4 private constant TRANSFERFROM_ACTION = bytes4(keccak256(bytes('_transferFrom(address,address,uint256)')));
	bytes4 private constant MINT_ACTION = bytes4(keccak256(bytes('mint(address,uint256)')));
	bytes4 private constant BURN_ACTION = bytes4(keccak256(bytes('burn(address,uint256)')));

	event PairCreated(address token0, address token1, address to);
	event AddLiquidity(address token0, address token1, uint amount0, uint amount1);
	event DeleteLiquidity(address token0, address token1, uint amount0, uint amount1, uint liquidity);
	event Swap(address token0, address token1, address _to, uint amount0, uint amount1);
	event SyncStorage(address token0, address token1, uint newBalance0, uint newBalance1);

	constructor(address _token0, address _token1, address _lp) {
		owner = msg.sender;
		token0 = _token0;
		token1 = _token1;
		lp = _lp;
	}

	function createPair(address _token0, address _token1, address _to) public {
		require(msg.sender == owner, 'Not owner');
		token0 = _token0;
		token1 =  _token1;
		emit PairCreated(_token0, _token1, _to);
	}

	function getBalancePair() private returns (uint balance0, uint balance1) {
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
			price0 = k / (balanceContract1);
			price1 = k / (balanceContract0);
        }

        reserve0 = balanceContract0;
        reserve1 = balanceContract1;
        emit SyncStorage(_token0, _token1, reserve0, reserve1);
	}

	function updateK(address _token0, address _token1) public returns (uint) {
		uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
		if(key == 0) {
			k = balance0 * balance1;
			key = 1;
		}
		return k;
	}

	function _addLiquidity(address _token0, address _token1, uint amount0, uint amount1) public returns (bool) {
		(uint balanceContract0, uint balanceContract1) = getBalancePair();
		require(_token0 == token0 && _token1 == token1, 'Not used address');
		require(amount0 == amount1, 'Not equal');
		TransferHelper.safeTransferFrom(_token0, msg.sender, address(this), amount0);
        TransferHelper.safeTransferFrom(_token1, msg.sender, address(this), amount1);

        uint _balance0 = IERC20(_token0).balanceOf(address(this));
	    uint _balance1 = IERC20(_token1).balanceOf(address(this));

        uint liquidity;
        if (totalSupply == 0) {
	        liquidity = Math.sqrt(((_balance0 - balanceContract0) * (_balance1 - balanceContract1)) - min_liq);
	        require(liquidity > 0, 'Minus liquidity');
	        mint(lp, msg.sender, liquidity);
	        updateK(_token0, _token1);
	    } else {
	        liquidity = Math.min(((_balance0 - balanceContract0) * totalSupply) / balanceContract0, ((_balance1 - balanceContract1) * totalSupply) / balanceContract1);
	        require(liquidity > 0, 'Minus liquidity');
	        mint(lp, msg.sender, liquidity);
	    }
	    totalSupply+=liquidity;
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        _updateStorage(_token0, _token1, balance0, balance1);
        emit AddLiquidity(_token0, _token1, amount0, amount1);
        return true;
	}

	function _deleteLiquidity(address _token0, address _token1, address _to, uint liquidity, uint amount0, uint amount1) public returns (bool) {
		(uint balanceContract0, uint balanceContract1) = getBalancePair();
		require(_token0 == token0 && _token1 == token1, 'Not used address');
		require(amount0 == amount1, 'Not equal');

	    uint amountDelLiq0 = (liquidity * balanceContract0) / totalSupply;
	    uint amountDelLiq1 = (liquidity * balanceContract1) / totalSupply;

	    require(amountDelLiq0 > 0 && amountDelLiq1 > 0, 'Minus amount');
	    burn(lp, _to, liquidity);
	   	TransferHelper.safeTransfer(_token0, _to, amountDelLiq0);
	   	TransferHelper.safeTransfer(_token1, _to, amountDelLiq1);

	    totalSupply -= liquidity;
	    uint newBalance0 = IERC20(_token0).balanceOf(address(this));
		uint newBalance1 = IERC20(_token1).balanceOf(address(this));
	    _updateStorage(_token0, _token1, newBalance0, newBalance1);
	    emit DeleteLiquidity(_token0, _token1, balanceContract0, balanceContract1, liquidity);
	    return true;
	}

	function _swap(address _token0, address _token1, address _to, uint amount0, uint amount1) public returns (bool) {
		(uint balanceContract0, uint balanceContract1) = getBalancePair();
		require(_token0 == token0 && _token1 == token1, 'Not used address');
		require(amount0 > 0 || amount1 > 0, 'Zero amount');
		require(_to != _token0 && _to != _token1, 'Not used address');

		if (amount0 > 0) TransferHelper.safeTransfer(_token0, _to, amount0);
        if (amount1 > 0) TransferHelper.safeTransfer(_token1, _to, amount1);

        uint newBalance0 = IERC20(_token0).balanceOf(address(this));
		uint newBalance1 = IERC20(_token1).balanceOf(address(this));
	    _updateStorage(_token0, _token1, newBalance0, newBalance1);
        emit Swap(_token0, _token1, _to, amount0, amount1);
        return true;
	}

}