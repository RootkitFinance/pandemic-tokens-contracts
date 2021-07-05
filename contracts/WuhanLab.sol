// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Uniswap/INonfungiblePositionManager.sol";
import "./Uniswap/IUniswapV3PoolActions.sol";
import "./Uniswap/IUniswapV3PoolImmutables.sol";
import "./Uniswap/IUniswapV3Factory.sol";
import "./Uniswap/IUniswapV3PoolActions.sol";
import "./Uniswap/IUniswapV3PoolState.sol";
import "./Uniswap/TickMath.sol";

import "./IERC20.sol";
import "./SafeMath.sol";
import "./VariantToken.sol";
import "./ILab.sol";
import "./FullMath.sol";
import "./FixedPoint96.sol";

contract WuhanLab is ILab {
    using SafeMath for uint256;

    mapping (address => bool) activeVariants;    
    mapping (uint256 => StrainData) public strains;
    mapping (address => VariantData) public variants;
    mapping (uint256 => address[]) public strainVariants;

    struct StrainData {
        address pairedToken;
        address[] variants;
        uint256 variantCount;
    }

    struct VariantData {       
        uint256 positionId; // updated every liquidity increment
        int24 currentTickLower; // updated every liquidity increment
        address pairedToken; // constructor / inherited from parent virus
        address poolAddress; // constructor
        bool isToken0; // constructor / token 1 and 0 sorted by numeric order ... 0x0, 0x1,0x2, ect ect
        int24 startTickLower; // this can be a randomization factor, just ensure the result is divisible by 200
        uint256 incrementRate; // new strains are all set at 400 - random(4) at variant creation -400, -200, -0, +200, result must be below burn, or -200.... 400 is the minimum
        uint256 burnRate; // all tokens set to 690 at start, random(369), 1 = -246, 369 = +123 ... minimum burn amount possible is 420
        uint256 strainNonce;
        uint256 variantNonce;
    }  
    
    INonfungiblePositionManager public immutable positionManager;
    IUniswapV3Factory public immutable uniswapV3Factory;
    IERC20 public immutable rootkit;
    address private immutable devAddress;
    uint256 public strainCount;

    uint24 public constant fee = 10000;
    int24 public constant tickSpacing = 200;

    event VariantCreated(address variant, address pairedToken);

     constructor(INonfungiblePositionManager _positionManager, IUniswapV3Factory _uniswapV3Factory, IERC20 _rootkit) {
        positionManager = _positionManager;
        uniswapV3Factory = _uniswapV3Factory;
        rootkit = _rootkit;
        devAddress = msg.sender;
    }

    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }
    
    function getLiquidityForAmountInRange(uint160 sqrtRatioUpper, uint160 sqrtRatioCurrent, uint256 amount
    ) internal pure returns (uint128 liquidity) {
        uint256 intermediate = FullMath.mulDiv(sqrtRatioUpper, sqrtRatioCurrent, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount, intermediate, sqrtRatioCurrent - sqrtRatioUpper));
    }

    function getAmountForLiquidityInRange(uint160 sqrtRatioUpper, uint160 sqrtRatioCurrent, uint128 liquidity
    ) internal pure returns (uint256 amount) {
        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioCurrent - sqrtRatioUpper,
                sqrtRatioCurrent
            ) / sqrtRatioUpper;
    }

    function calculateExcessLiquidity(address variantToken) private view returns (uint256) {
        VariantData memory variantData = variants[variantToken];
        IERC20 variant = IERC20(variantToken);
        IERC20 paired = IERC20(variantData.pairedToken);
        uint256 circulatingSupply = variant.totalSupply().sub(variant.balanceOf(variantData.poolAddress));
        uint160 tickBoundaryPrice = TickMath.getSqrtRatioAtTick(variantData.currentTickLower + 200);
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3PoolState(variantData.poolAddress).slot0();
        uint128 pairedAsLiquidity = getLiquidityForAmountInRange (tickBoundaryPrice, sqrtPriceX96, circulatingSupply);
        uint256 needed = getAmountForLiquidityInRange(tickBoundaryPrice, sqrtPriceX96, pairedAsLiquidity);
        uint256 pairedInPool = paired.balanceOf(variantData.poolAddress);
        return ((needed - pairedInPool) * 100 / pairedInPool); //math maybe wrong... 
    }

    function incrementLiquidity(address variantToken) public override { // raise the price of a variant token by 4% or more  
        VariantData storage variantData = variants[variantToken];
        
        if (calculateExcessLiquidity(variantToken) < variantData.incrementRate + 20) { return; }    

        positionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId: variantData.positionId,
            recipient: devAddress,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max }));

        removeLiquidity(variantData.positionId, variantData.poolAddress);
        positionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId: variantData.positionId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max }));

        variantData.currentTickLower = variantData.currentTickLower + int24(variantData.incrementRate);
     
        addLiquidity(variantToken, variantData.pairedToken, variantData.currentTickLower, variantData.isToken0);
    }

    function eatExoticAnimal() public override {
        address spreader = msg.sender;
        require (activeVariants[spreader], "Unknown variant");

        VariantData memory parentVariantData = variants[spreader];
        createNewVariant(parentVariantData.pairedToken, parentVariantData.currentTickLower + tickSpacing, parentVariantData.strainNonce, parentVariantData.burnRate, parentVariantData.incrementRate);
    }

    function labLeak(address pairedToken, int24 startingTick) public {// no amount of saftey checks can prevent rugs and broken tokens being added, so no checks are done...
        if (msg.sender != devAddress){
            rootkit.transferFrom(msg.sender, address(this), 11e16); // it costs 0.11 ROOT to start a virus with a new variant pair
        }

        IERC20 paired = IERC20(pairedToken);

        if (paired.allowance(address(this), address(positionManager)) < 1) {
            paired.approve(address(positionManager), uint256(-1));
        }

        strainCount++;
        address[] memory strainVariants;
        strains[strainCount] = StrainData({            
            pairedToken: pairedToken,
            variantCount: 0,
            variants: strainVariants
        });
        createNewVariant(pairedToken, startingTick, strainCount, 0, 0);        
        // maybe we let the user do a buy here to encourage more people to do it
    }    

    function createNewVariant(address pairedToken, int24 tick, uint256 strainNonce, uint256 parentBurnRate, uint256 parentIncrementRate) private {
        uint256 variantNonce = ++strains[strainCount].variantCount;
        uint256 burnRate = parentBurnRate == 0 ? 690 : parentBurnRate + random(strainNonce, variantNonce, 369) - 246;
        uint256 incrementRate = parentIncrementRate == 0 ? 400 : parentIncrementRate + random(strainNonce, variantNonce, 3) * 200 - 400;

        if (incrementRate < 400) {
            incrementRate = 400;
        }

        if (burnRate < 420) {
            incrementRate = 420;
        }

         if (burnRate < incrementRate) {
            incrementRate -= 200;
        }

        VariantToken newVariant = new VariantToken(burnRate);
        address newVariantAddress = address(newVariant);
        
        bool isToken0 = newVariantAddress < pairedToken;
        address poolAddress = uniswapV3Factory.createPool(newVariantAddress, pairedToken, fee);
        IUniswapV3PoolActions(poolAddress).initialize(TickMath.getSqrtRatioAtTick(isToken0 ? tick : tick + tickSpacing));
       
        newVariant.approve(address(positionManager), uint256(-1));

        uint256 positionId = addLiquidity(newVariantAddress, pairedToken, tick, isToken0);
        
        activeVariants[address(newVariant)] = true;
       
        variants[newVariantAddress] = VariantData({
            positionId: positionId,
            currentTickLower: tick,
            pairedToken: pairedToken,
            poolAddress: poolAddress,
            isToken0: isToken0,
            startTickLower: tick,
            incrementRate: incrementRate,
            burnRate: burnRate,
            strainNonce: strainNonce,
            variantNonce: variantNonce
        });
        
        strainVariants[strainCount].push(newVariantAddress);
        strains[strainCount].variants.push(newVariantAddress);
        emit VariantCreated(newVariantAddress, pairedToken);
    }

    function addLiquidity(address variantToken, address pairedToken, int24 tick, bool isToken0) private returns(uint256) {
 
        (address token0, address token1) = isToken0 ? (variantToken, pairedToken) : (pairedToken, variantToken);
        uint256 variantBalance = IERC20(variantToken).balanceOf(address(this));
        uint256 pairedBalance = IERC20(pairedToken).balanceOf(address(this));
        (uint256 amount0Desired, uint256 amount1Desired) = isToken0 ? (variantBalance, pairedBalance) : (pairedBalance, variantBalance);
        (uint256 tokenId,,,) = positionManager.mint(INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: tick,
            tickUpper: tick + tickSpacing,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        }));

        return tokenId;
    }

    function removeLiquidity(uint256 tokenId, address poolAddress) private {      
        positionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: IUniswapV3PoolState(poolAddress).liquidity(),
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        }));
    }

    function random(uint256 strainNonce, uint256 variantNonce, uint256 max) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, strainNonce, variantNonce))) % max + 1;
    }

    function recoverTokens(IERC20 token) public {
        require (msg.sender == devAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function resetMaxApproval(IERC20 token) public{
        token.approve(address(positionManager), uint256(-1));
    }
}
