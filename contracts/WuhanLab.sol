// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./TokensRecoverable.sol";
import "./INonfungiblePositionManager.sol";
import "./IQuoter.sol"

contract WuhanLab is TokensRecoverable
{
    struct PoolInfo {
        address pairedToken;
        uint256 currentTick;
        uint256 tokenId;
    }

    mapping (address => PoolInfo) pools;
    INonfungiblePositionManager public immutable positionManager;
    IQuoter public immutable quoter;

    constructor(INonfungiblePositionManager _positionManager, IQuoter _quoter)
    {
        positionManager = _positionManager;
        quoter = _quoter;
    }

    function addLiquidity(IERC20 variantToken, address pairedToken, uint256 startingTick)
    {        
        (uint256 tokenId,,,) = positionManager.mint(MintParams {
            address(variantToken),
            address(pairedToken),
            200,
            startingTick,
            startingTick+200,
            variantToken.balanceOf(address(this)),
            0,
            0,
            0,
            address(this),
            block.timestamp
        });

        pools[address(variantToken)] = PoolInfo({pairedToken, startingTick});
    }
    
    function calculateExcessLiquidity(address variantToken) private view returns (uint256)
    {
         uint256 out = quoter.quoteExactInput(abi.encodePacked(variantToken, 200, pools[variantToken].pairedToken), circulatingSupply)
        // circulatingSupply = total supply - UpOnly in pool - collected fees
        // availableLiquidity = tokens in pool
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
}
