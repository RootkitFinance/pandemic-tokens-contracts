// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./ERC20.sol";

contract VariantToken is ERC20
{
    uint256 public constant burnRate;
    IUniswapV3Factory public constant uniswapV3Factory;
    WuhanLab public constant wuhanLab;

    struct variantParams{
        address pairToken;
        uint128 startingTick;
        address pool;
    }

    constructor()
    {
        burnRate = 690;
        uniswapV3Factory = IUniswapV3Factory(address("0x"));
        wuhanLab = WuhanLab(address(msg.sender));
        variantParams = wuhanLab.checkNewPoolParams();
        IUniswapV3PoolActions pool = IUniswapV3PoolActions(uniswapV3Factory.createPool(address(this), variantParams[pairToken], 200));
        pool.initialize(startingTick); 
        variantParams[pool] = address(pool);
        _mint(address(wuhanLab), 70**12 ether);
    }

    function superSpreader()public
    {
        wuhanLab.incrementLiquidity(address(this));
    }

    function mutateNewVariant() public 
    {
        wuhanLab.eatAnExoticAnimal();
    }

    //move ERC20 functions diectly here, only import interface, only keep needed functions, similar to UniswapV2ERC20 
    // transfer function requirements
    // - only the factory is exempt from fees and all other restriictions 
    // - sender or receiver must be the pool
    // - burn on transfer
    // - require extcode size == 0 .......... = no inline assembly .... we dont want contracts interacting with the tokens

}
