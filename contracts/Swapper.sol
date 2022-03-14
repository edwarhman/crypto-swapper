//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Swapper is Initializable {
    ISwapRouter public swapRouter;

    function initialize(ISwapRouter _swapRouter) public {
        swapRouter = _swapRouter;
    }
}
