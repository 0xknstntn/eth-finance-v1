pragma solidity ^0.8.0;

interface IOndaV1LendingPool {
    event NewBorrow(address _stablecoin, address _aToken, address _borrower, uint amount);
    event DeleteBorrow(address _stablecoin, address _aToken, address _borrower, uint amount);
    event NewLend(address token0, address token1, uint amount0);
    event DeleteLend(address token0, address token1, uint amount0);
    event SyncStorage(address _stablecoin, address _aToken, uint newBalance0, uint newtotalSupply);
    event NewLendingPool(address _stablecoin, address _aToken);

    function createLendingPool(address _stablecoin, address _router) external;
    function _addLend(address _stablecoin, address _aToken, address _to, uint amount0) external returns (bool);
    function _deleteLend(address _stablecoin, address _aToken, address _to, uint amount0) external returns (bool);
    function _infoBorrow(address _to) external returns (uint amount);
    function _newBorrow(address _stablecoin, address _aToken, address _to, uint amount0, uint amountRouter) external payable returns (bool);
    function _deleteBorrow(address _stablecoin, address _aToken, address payable _to, uint amount) external payable returns (bool);
    function flashLoan(uint256 amount) external;
    function execute() external;
}