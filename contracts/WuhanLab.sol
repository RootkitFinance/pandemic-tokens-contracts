// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Uniswap/INonfungiblePositionManager.sol";
import "./Uniswap/IUniswapV3PoolActions.sol";
import "./Uniswap/IUniswapV3PoolImmutables.sol";
import "./Uniswap/IUniswapV3Factory.sol";
import "./Uniswap/IQuoter.sol";
import "./Uniswap/TickMath.sol";

import "./IERC20.sol";
import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./VariantToken.sol";
import "./ILab.sol";

contract WuhanLab is ILab, TokensRecoverable {
    using SafeMath for uint256;

    mapping (address => bool) activeVariants;    
    mapping (uint256 => StrainData) public strains;
    mapping (address => VariantData) public variants;

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
        //uint160 startSqrtPriceX96; // we dont really need this, its always best to calculate from the closest tick
        int24 startTickLower; // this can be a randomization factor, just ensure the result is divisible by 200
        uint256 incrementRate; // new strains are all set at 400 - random(4) at variant creation -400, -200, -0, +200, result must be below burn, or -200.... 400 is the minimum
        uint256 burnRate; // all tokens set to 690 at start, random(369), 1 = -246, 369 = +123 ... minimum burn amount possible is 420
        uint256 strainNonce;
        uint256 variantNonce;
    }  
    
    INonfungiblePositionManager public immutable positionManager;
    IUniswapV3Factory public immutable uniswapV3Factory;
    IQuoter public immutable quoter; // remove quoter    
    IERC20 public immutable rootkit;
    address private immutable devAddress;
    uint256 public strainCount;

    uint24 public constant fee = 200;

    event VariantCreated(address variant, address pairedToken);

    constructor(INonfungiblePositionManager _positionManager, IUniswapV3Factory _uniswapV3Factory, IQuoter _quoter, IERC20 _rootkit) {
        positionManager = _positionManager;
        uniswapV3Factory = _uniswapV3Factory;
        quoter = _quoter;
        rootkit = _rootkit;
        devAddress = msg.sender;
    }

    function calculateExcessLiquidity(address variantToken) private returns (uint256) { // still studying this, lots to fix
        VariantData memory variantData = variants[variantToken];
        IERC20 variant = IERC20(variantToken);
        IERC20 paired = IERC20(variantData.pairedToken);    
        uint256 circulatingSupply = variant.totalSupply().sub(variant.balanceOf(variantData.poolAddress));
        uint256 quote = quoter.quoteExactInputSingle(variantToken, variantData.pairedToken, fee, circulatingSupply, TickMath.getSqrtRatioAtTick(variantData.currentTickLower));
        uint256 pairedInPool = paired.balanceOf(variantData.poolAddress);
        uint256 excessLiquidity = pairedInPool.sub(quote);
        return excessLiquidity.mul(10000).div(pairedInPool).div(10000);   
    }

    function incrementLiquidity(address variantToken) public override { // raise the price of a variant token by 4% or more  
        VariantData memory variantData = variants[variantToken];
        
        if (calculateExcessLiquidity(variantToken) < variantData.incrementRate + 20) { return; }

        positionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId: variantData.positionId,
            recipient: devAddress,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max }));

        removeLiquidity(variantData.positionId);
        
        addLiquidity(variantToken, variantData.pairedToken, variantData.currentTickLower + int24(variantData.incrementRate));
    }

    function eatExoticAnimal() public override {
        address spreader = msg.sender;
        require (activeVariants[spreader], "Unknown variant");

        VariantData memory parentVariantData = variants[spreader];
        createNewVariant(parentVariantData.pairedToken, parentVariantData.currentTickLower, parentVariantData.strainNonce, parentVariantData.burnRate, parentVariantData.incrementRate);
    }

    function labLeak(address pairedToken, int24 startingTick) public {// no amount of saftey checks can prevent rugs and broken tokens being added, so no checks are done...
        if (msg.sender != devAddress){
            rootkit.transferFrom(msg.sender, address(this), 1 ether); // it costs 1 ROOT to start a virus with a new variant pair
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
            incrementRate-=200;
        }

        VariantToken newVariant = new VariantToken(burnRate);
        address newVariantAddress = address(newVariant);
        address poolAddress = positionManager.createAndInitializePoolIfNecessary(newVariantAddress, pairedToken, fee, TickMath.getSqrtRatioAtTick(tick));
        newVariant.setPoolAddress(poolAddress);       
        uint256 positionId = addLiquidity(newVariantAddress, pairedToken, tick);
        
        activeVariants[address(newVariant)] = true;
       
        variants[newVariantAddress] = VariantData({
            positionId: positionId,
            currentTickLower: tick,
            pairedToken: pairedToken,
            poolAddress: poolAddress,
            isToken0: IUniswapV3PoolImmutables(poolAddress).token0() == newVariantAddress,
            startTickLower: tick,
            incrementRate: incrementRate,
            burnRate: burnRate,
            strainNonce: strainNonce,
            variantNonce: variantNonce
        });
        
        strains[strainCount].variants.push(newVariantAddress);
        emit VariantCreated(newVariantAddress, pairedToken);
    }

    function addLiquidity(address variantToken, address pairedToken, int24 tick) private returns(uint256) {
        (uint256 tokenId,,,) = positionManager.mint(INonfungiblePositionManager.MintParams({
            token0: variantToken,
            token1: pairedToken,
            fee: fee,
            tickLower: tick,
            tickUpper: tick + int24(fee),
            amount0Desired: type(uint128).max,
            amount1Desired: type(uint128).max,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        }));

        return tokenId;
    }

    function removeLiquidity(uint256 tokenId) private {      
        positionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: type(uint128).max,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        }));
    }

    function random(uint256 strainNonce, uint256 variantNonce, uint256 max) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, strainNonce, variantNonce))) % max + 1;
    }
}
