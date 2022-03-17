pragma solidity ^0.8.0;

import "../SwapperV2.sol";

contract SwapperTestV2 is SwapperV2 {
	function bestDexSwapETHForTokens(
        bytes memory data,
        uint srcAmount
    ) external
    payable {
        _bestDexSwapETHForTokens(data, srcAmount);
    }
}