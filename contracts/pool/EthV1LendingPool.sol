pragma solidity >=0.8.0;

import "../interface/IERC20.sol";
import "../interface/TransferHelper.sol";
import "../interface/Math.sol";
import "../token/aToken.sol";

interface IFlashLoanReceiver {
    function execute() external payable;
}

contract EthV1LendingPool {

    address public factory;
    address public router;

    address public stablecoin;
    address public aToken;

    uint public reserve0;
    uint public totalSupply;
    uint public constant min_liq = 10**2;
    uint public percentBorrow = 18;
    uint public percentLend = 15;
    uint public feeFlashloan = 300;

    mapping(address => uint) private _borrow;
    mapping(address => uint) private _timeLend;
    mapping(address => uint) private _timeBorrow;

    bytes4 private constant TRANSFER_ACTION = bytes4(keccak256(bytes('_transfer(address,uint256)')));
    bytes4 private constant TRANSFERFROM_ACTION = bytes4(keccak256(bytes('_transferFrom(address,address,uint256)')));
    bytes4 private constant MINT_ACTION = bytes4(keccak256(bytes('mint(address,uint256)')));
    bytes4 private constant BURN_ACTION = bytes4(keccak256(bytes('burn(address,uint256)')));

    event NewBorrow(address _stablecoin, address _aToken, address _borrower, uint amount);
    event DeleteBorrow(address _stablecoin, address _aToken, address _borrower, uint amount);
    event NewLend(address token0, address token1, uint amount0);
    event DeleteLend(address token0, address token1, uint amount0);
    event SyncStorage(address _stablecoin, address _aToken, uint newBalance0, uint newtotalSupply);
    event NewLendingPool(address _stablecoin);

    modifier onlyOwner {
        require(msg.sender == factory, "Not factory");
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    function createLendingPool(address _stablecoin, address _router) public onlyOwner {
        stablecoin = _stablecoin;
        aToken = address(new atoken(address(this)));
        router = _router;
        emit NewLendingPool(_stablecoin);
    }

    function getStorage() private returns (uint balance0) {
        balance0 = reserve0;
    }

    function transfer(address to, address token, uint amount) private {
        (bool status, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_ACTION, to, amount));
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

    function _updateStorage(address _stablecoin, address _aToken, uint256 _balance0, uint256 _totalSupply) private {
        require((_balance0 >= 0) && (_totalSupply >= 0), '0 number');
        reserve0 = _balance0;
        totalSupply = _totalSupply;
        emit SyncStorage(_stablecoin, _aToken, reserve0, totalSupply);
    }

    function _addLend(address _stablecoin, address _aToken, address _to, uint amount0) public returns (bool) {
        uint balance0 = getStorage();
        require(_stablecoin== stablecoin && _aToken == aToken, 'Not equal address');
        require(amount0 > 0, 'Not equal');
        uint _balance_stablecoin = IERC20(_stablecoin).balanceOf(address(this));
        TransferHelper.safeTransferFrom(_stablecoin, _to, address(this), amount0);
        mint(aToken, _to, amount0);
        totalSupply+=amount0;
        uint256 balance_stablecoin = IERC20(_stablecoin).balanceOf(address(this));
        uint256 balance_aToken = IERC20(_aToken).balanceOf(_to);
        _timeLend[_to] = block.timestamp;
        require((balance_stablecoin - _balance_stablecoin) == balance_aToken, 'Not equal');
        _updateStorage(_stablecoin, _aToken, balance_stablecoin, totalSupply);
        emit NewLend(_stablecoin, _aToken, amount0);
        return true;
    }

    function _deleteLend(address _stablecoin, address _aToken, address _to, uint amount0) public returns (bool) {
        uint balanceContract0 = getStorage();
        require(_stablecoin== stablecoin && _aToken == aToken, 'Not equal address');
        require(amount0 > 0, 'Not equal');
        uint time_lend = (block.timestamp - _timeLend[_to]) / 86400;
        require(time_lend >= 3, 'Min 3 day');

        burn(_aToken, _to, amount0);
        TransferHelper.safeTransferFrom(_stablecoin, address(this), _to, ((((((amount0 * (percentLend * 100)) / 100) * time_lend) / 365) / 100 ) + amount0));

        totalSupply -= amount0;
        uint balance_stablecoin = IERC20(_stablecoin).balanceOf(address(this));
        _updateStorage(_stablecoin, _aToken, balance_stablecoin, totalSupply);
        emit DeleteLend(_stablecoin, _aToken, amount0);
        return true;
    }

    function _infoBorrow(address _to) public returns (uint amount) {
        return _borrow[_to];
    }

    function _newBorrow(address _stablecoin, address _aToken, address _to, uint amount0, uint amountRouter) public payable returns (bool) {
        require(msg.sender == router, 'Create borrow with a router');
        uint balanceContract0 = getStorage();
        require(_stablecoin== stablecoin && _aToken == aToken, 'Not equal address stablecoin/aToken');
        require(amount0 > 0, 'Amount negative');
        require(((amountRouter * 80)/100) == ((amount0 / 100) * 100000000000000000), 'Wrong _amount');
        _timeBorrow[_to] = block.timestamp;
        IERC20(_stablecoin).transferFrom(address(this), _to, amount0);
        _borrow[_to] += amount0;
        uint balance_stablecoin = IERC20(_stablecoin).balanceOf(address(this));
        _updateStorage(_stablecoin, _aToken, balance_stablecoin, totalSupply);
        emit NewBorrow(_stablecoin, _aToken, _to, amount0);
        return true;
    }

    function _deleteBorrow(address _stablecoin, address _aToken, address payable _to, uint amount) public payable returns (bool) {
        uint balanceContract0 = getStorage();
        require(_stablecoin== stablecoin && _aToken == aToken, 'Not equal address');
        require(amount >= _borrow[_to], 'Not equal');
        uint time_borrow = (block.timestamp - _timeBorrow[_to]) / 86400;
        require(time_borrow >= 1, 'Min 1 day');
        uint amountBorrow = _borrow[_to];
        require(((((((amountBorrow * (percentBorrow * 100)) / 100) * time_borrow) / 365) / 100 ) + amountBorrow) < amount, "Not equal amount");

        uint amount_to_ether = ((amountBorrow / 80) * 100) * 1000000000000000;
        IERC20(_stablecoin).transferFrom(_to, address(this), amount);
        _to.send(amount_to_ether);
        _borrow[_to] = 0;
        uint balance_stablecoin = IERC20(_stablecoin).balanceOf(address(this));
        _updateStorage(_stablecoin, _aToken, balance_stablecoin, totalSupply);
        emit DeleteBorrow(_stablecoin, _aToken, _to, (msg.value / 1000000000000000000));
        return true;

    }

     function flashLoan(uint256 amount) public {
        require(msg.sender != tx.origin, 'msg.sender should be contract');
        uint256 balanceBefore = IERC20(stablecoin).balanceOf(address(this));
        require(balanceBefore >= amount, "Not enough stablecoin in balance");
        IERC20(stablecoin).transfer(msg.sender, (amount));
        IFlashLoanReceiver(msg.sender).execute();
        uint256 balanceAfter = IERC20(stablecoin).balanceOf(address(this));
        require(balanceAfter > balanceBefore, "Flash loan hasn't been paid back");        
    }

}
