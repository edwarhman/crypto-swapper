pragma solidity ^0.8.0;

import "./Swapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

///@title Crypto Swapper
///@author Emerson Warhman
///@notice You can swap your ETH for any other ERC20 token in Ethereum network
///@notice Swap your ETH for multiple tokens in the same transaction
contract SwapperV2 is Initializable, AccessControlUpgradeable {
    ///@notice router used to manage the swap
    IUniswapV2Router01 public swapRouter;
    ///@notice fee charged by the contract in every transaction
    uint public fee;
    ///@notice address of the recipient of the fee charges
    address public recipient;
    ///@notice Role required to manipulate admin functions
    bytes32 public constant ADMIN = keccak256("ADMIN");
    address public paraswapRouter;

    ///@notice Event emitted when a swap is done successfuly
    ///@param ethAmount amount of ETH sent in the transaction
    ///@param tokenAmount Amount of the token received
    ///@param tokenAddress address of the token received 
    event EthSwapped (
        uint ethAmount,
        uint tokenAmount,
        address tokenAddress
    );

    //functions

    ///@notice initialize contract state variables
    ///@param _swapRouter address of the uniswap V2 router  
    ///@param _fee Transactions' fee (ex. to set a fee of 0.1% put 1)
    ///@param _recipient Address of the recipient of the charged fees
    function initialize(
        IUniswapV2Router01 _swapRouter,
        uint _fee,
        address _recipient
    ) public
    initializer {
        swapRouter = _swapRouter;
        fee = _fee;
        recipient = _recipient;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
    }

    ///@notice Allow to swap ETH for multiple tokens in one transaction
    ///@param tokensAddresses Array of all the tokens to receive in the swap
    ///@param tokensPercents Array of the percents to receive for each token
    ///@param tokensPrices Min expected prices for each token
    ///@dev All arrays must have the same length
    function swapMultipleTokens(
        address[] memory tokensAddresses,
        uint[] memory tokensPercents,
        uint[] memory tokensPrices
    ) external
    payable {
        require(tokensAddresses.length == tokensPercents.length
                && tokensPercents.length == tokensPrices.length,
                "Arguments arrays must have equal size");
        require(_percentsAreCorrect(tokensPercents), 
                "The sum of the percents cannot exceeds 100");

        uint amount = msg.value;
        uint toCharge = amount * fee / 1000;
        amount -= toCharge;

        _chargeFee(toCharge);
        // swap each token one by one
        for(uint i; i < tokensAddresses.length; i++) {
            address token = tokensAddresses[i];
            uint percent = tokensPercents[i];
            uint amountIn = amount * percent / 100 ;
            uint amountOutMin = amountIn * tokensPrices[i] / (1 ether); 
            _swapETHForTokens(
                amountIn,
                amountOutMin,
                token
            );
        }
    }

    ///@notice Set the charges recipient
    ///@param _recipient Address of the new recipient 
    function setRecipient(address _recipient) external onlyRole(ADMIN) {
        recipient = _recipient;
    }

    ///@notice Set the transaction fee
    ///@param _fee Transactions' fee (ex. to set a fee of 0.1% put 1)
    function setFee(uint _fee) external onlyRole(ADMIN) {
        fee = _fee;
    }

    ///@notice Swap the specified amount of ETH for the specified token
    ///@param amountIn amount of ETH to swap
    ///@param amountOutMin Min token amount expected to receive for the ETH
    ///@param tokenAddress Address of the token
    function _swapETHForTokens(
        uint256 amountIn,
        uint amountOutMin,
        address tokenAddress
    ) internal {
        address[] memory path = new address[](2);
        uint [] memory amounts;
        path[0] = swapRouter.WETH();
        path[1] = tokenAddress;

        amounts = swapRouter.swapExactETHForTokens{value: amountIn}(
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        emit EthSwapped(
            amounts[0],
            amounts[1],
            tokenAddress
        );
    }

    ///@notice Necessary to check if percents specified in swapMultipleToken are valid
    ///@notice The sum of all the percents must be less than 100
    ///@param percents Array of the percents to check
    function _percentsAreCorrect(
        uint[] memory percents
    ) internal
    pure
    returns(bool result) {
        uint sum;
        for(uint i = 0; i < percents.length; i++) {
            sum += percents[i];
        }
        result = sum <= 100;
        return result;
    }

    ///@notice transfer charged fee to the recipient
    ///@param toCharge total amount of ETH to transfer
    function _chargeFee(
        uint toCharge
    ) internal {
        (bool fe,) = payable(recipient).call{value: toCharge}("");
        require(fe, "ETH was not sent to recipient");
    }

    function bestDexSwapETHForTokens(
        bytes[] memory data,
        IERC20[] calldata tokens 
    ) external
    payable {
        require(data.length == tokens.length, "Arguments arrays must have equal size");
        uint received;
        console.log("bestDexSwap starts");
        for(uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = paraswapRouter.call{value: msg.value}(data[i]);
            if(!success) {
                uint l = result.length;
                if(l < 68) {
                    revert("Function reverted without error messages");
                }
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            console.log(success);
            received = abi.decode(result, (uint));

            uint toCharge = received * fee / 1000;

            tokens[i].transfer(recipient, toCharge);

            tokens[i].transfer(msg.sender, received - toCharge);
        }
    }

    function setParaswapRouter(
        address _paraswapRouter
    ) external {
        paraswapRouter = _paraswapRouter;
    }

}
 