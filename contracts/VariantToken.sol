// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./ERC20.sol";

contract VariantToken is ERC20
{
    uint256 public spread;
    address private constant devAddress;

    constructor(uint256 _tickSpace, uint256 _spread, uint256 _price, IERC20 _pairToken)
    {
        spread = _spread;
        // create uni v3 pool (tickSpace, this, pairToken)
        // _price is where to put our token in the pool
        // _spread is how may ticks below price to put the other side of liquidity 
        // add one side of liq with 100 ** 69  
    }

    function calculateExcessLiquidity() private view returns (uint256)
    {
        // circulatingSupply = total supply - UpOnly in pool - collected fees
        // availableLiquidity = tokens in pool - collected fees
        // After selling circulatingSupply into availableLiquidity - what is percent of availableLiquidity is left over
        
    }

    function incrementLiquidity() public 
    {
        uint256 result = calculateExcessLiquidity();
        if (result < 200) { return; }
        
        // remove upOnly liq
        // Add back 1 tick higher
        // remove token liq
        // take dev cut
        // put 1 tick higher
    }

    function spreadVirus() public 
    {
        //launch the clone with mutation
    }

    // no add liq
    
    // transfer  - sender or receiver must be a pool!!!!


}
