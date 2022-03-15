pragma solidity ^0.8.0;

import "../Swapper.sol";

contract SwapperTest is Swapper {
	function swapETHForTokens(
        uint256 amountIn,
        uint amountOutMin,
        address tokenAddress
    ) external
    payable {
        _swapETHForTokens(
        	amountIn,
        	amountOutMin,
        	tokenAddress
        );
    }
}