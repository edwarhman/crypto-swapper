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

    function swapMultipleTokens(
        address[] memory tokensAddresses,
        uint[] memory tokensPercents,
        uint[] memory tokensPrices
    ) external
    payable {
        require(tokensAddresses.length == tokensPercents.length
                && tokensPercents.length == tokensPrices.length,
                "Arguments arrays must have equal size");
        require(_percentsAreCorrect(tokensPercents), "The sum of the percents cannot exceeds 100");
        for(uint i; i < tokensAddresses.length; i++) {
            address token = tokensAddresses[i];
            uint percent = tokensPercents[i];
            uint amountIn = msg.value * percent / 100 ;
            uint amountOutMin = amountIn * tokensPrices[i] / (1 ether); 
            _swapETHForTokens(
                amountIn,
                amountOutMin,
                token
            );
        }
    }

    function _swapETHForTokens(
        uint256 amountIn,
        uint amountOutMin,
        address tokenAddress
    ) internal {
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = tokenAddress;
        swapRouter.swapExactETHForTokens{value: amountIn}(
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );
    }

    function _percentsAreCorrect(uint[] memory percents) internal returns(bool result) {
        uint sum;
        for(uint i = 0; i < percents.length; i++) {
            sum += percents[i];
        }
        result = sum <= 100;
        return result;
    }
}
