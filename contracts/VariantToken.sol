// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./ERC20.sol";

contract VariantToken is ERC20
{
    uint256 public burnRate;
    address private constant devAddress;
    IUniswapV3Factory public uniswapV3Factory;
    WuhanLab public wuhanLab;

    constructor(uint256 _tickSpace, uint256 _burnRate, uint256 _price, IERC20 _pairToken)
    {
        burnRate = _burnRate;
        uniswapV3Factory = IUniswapV3Factory(address("0x"));
        wuhanLab = WuhanLab(address("0x"));
        IUniswapV3PoolActions pool = IUniswapV3PoolActions(uniswapV3Factory.createPool(address(this), address(_pairToken), 200));
        pool.initialize();
        _mint(address(wuhanLab), 70**12 ether);
        wuhanLab.addLiquidity(address(this), address(_pairToken), 0); //startingTick = sqr
        // _price is where to put our token in the pool
        // _spread is how may ticks below price to put the other side of liquidity 
        // add one side of liq with 100 ** 69  
    }

    function spreadVirus() public 
    {
        //launch the clone with mutation
    }

    // no add liq
    
    // transfer  - sender or receiver must be a pool!!!!


}
