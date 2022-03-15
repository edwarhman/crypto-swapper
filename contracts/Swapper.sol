//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Swapper is Initializable {
    IUniswapV2Router01 public swapRouter;

    function initialize(IUniswapV2Router01 _swapRouter) public {
        swapRouter = _swapRouter;
    }

    function _swapETHForTokens(
        uint256 amountIn,
        uint amountOutMin,
        address tokenAddress
    ) internal {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = swapRouter.WETH();
        swapRouter.swapExactETHForTokens{value: amountIn}(
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );
    }
}
