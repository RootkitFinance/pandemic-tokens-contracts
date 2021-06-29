// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Uniswap/INonfungiblePositionManager.sol";
import "./Uniswap/IUniswapV3PoolActions.sol";
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
        address[] allVariants;
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
        uint256 stainNonce;
        uint256 varientNonce;
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


        // was to be called during increment
    function updateLiquidityParams(address variant) private returns (int24 newTick, int24 tickUpper, uint160 newPrice){ // most token data and variables tracked here, 
        int24 nextTick = variantData.currentTickLower + variantData.incrementRate;
        variantData.currentTickLower + variantData.incrementRate;
        variantData.CurrentSqrtPriceX96 = TickMath.getSqrtRatioAtTick(nextTick);
    }

    function incrementReady(address variantToken) private view returns(bool){ }

    function calculateExcessLiquidity(address variantToken) private returns (uint256) { // still studying this, lots to fix
        VarientData varientData = varients[variantToken];
        IERC20 variant = IERC20(variantToken);       
        uint256 circulatingSupply = variant.totalSupply().sub(variant.balanceOf(varientData.poolAddress));


        uint256 quote = quoter.quoteExactInputSingle(variantToken, pairedToken, fee, circulatingSupply, TickMath.getSqrtRatioAtTick(varientData.currentTickLower));
        uint256 pairedInPool = paired.balanceOf(varientData.poolAddress);
        uint256 excessLiquidity = pairedInPool.sub(quote);
        return excessLiquidity.mul(10000).div(pairedInPool).div(10000);
        // circulatingSupply = total supply - UpOnly in pool - collected fees
        // availableLiquidity = tokens in pool
        // After selling circulatingSupply into availableLiquidity - what is percent of availableLiquidity is left over       
    }

    function incrementLiquidity(address variantToken) public override { // raise the price of a variant token by 4% or more  
        uint256 tokenId = variantPositions[variantToken];
        (,, address token0, address token1,, int24 tickLower,,,,, uint128 tokensOwed0, uint128 tokensOwed1) = positionManager.positions(tokenId);
        address pairedToken = token0 == variantToken ? token1 : token0;//cleanup

        uint256 result = calculateExcessLiquidity(variantToken, pairedToken);
        
        if (result < 420) { return; }     //increment rate + 20

        positionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: devAddress,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max }));

        removeLiquidity(tokenId);

        addLiquidity(variantToken, pairedToken, tickLower + 400);//increment rate
    }

    /*function calculateExcessLiquidity(address variantToken, address pairedToken) private returns (uint256) {
        IERC20 variant = IERC20(variantToken);
        IERC20 paired = IERC20(pairedToken);
        address pool = uniswapV3Factory.getPool(variantToken, pairedToken, fee);
        uint256 circulatingSupply = variant.totalSupply().sub(variant.balanceOf(pool));
        uint256 quote = quoter.quoteExactInput(abi.encodePacked(variantToken, pairedToken, fee), circulatingSupply);
        uint256 pairedInPool = paired.balanceOf(pool);
        uint256 excessLiquidity = pairedInPool.sub(quote);
        return excessLiquidity.mul(10000).div(pairedInPool).div(10000);
        // circulatingSupply = total supply - UpOnly in pool - collected fees
        // availableLiquidity = tokens in pool
        // After selling circulatingSupply into availableLiquidity - what is percent of availableLiquidity is left over       
    }*/

    function eatExoticAnimal() public override {
        address spreader = msg.sender;
        require (activeVariants[spreader], "The animal isn't a spreader");
        VariantData parentVariantData = variants[spreader];
        uint256 strainNonce = parentVariantData.strainNonce;
        StrainData strainData = strains[strainNonce];
        createNewVariant(pairedToken, tick, strainNonce, ++strainData.variantCount);
    }

    function labLeak(address newPairedToken, int24 startingTick) public {// no amount of saftey checks can prevent rugs and broken tokens being added, so no checks are done...
        if (msg.sender != devAddress){
            rootkit.transferFrom(msg.sender, address(this), 1 ether); // it costs 1 ROOT to start a virus with a new variant pair
        }
        strainCount++;
        createNewVariant(newPairedToken, startingTick, strainCount, ++strainVariantsCount[strainCount]);
        // maybe we let the user do a buy here to encourage more people to do it
    }    

    function createNewVariant(address pairedToken, int24 tick, uint256 strainNonce, uint256 variantNonce) private {       
        VariantToken newVariant = new VariantToken();
        address newVariantAddress = address(newVariant);
        address poolAddress = positionManager.createAndInitializePoolIfNecessary(newVariantAddress, pairedToken, fee, TickMath.getSqrtRatioAtTick(tick));
        newVariant.setPoolAddress(poolAddress);       
        uint256 positionId = addLiquidity(newVariantAddress, pairedToken, tick);      
        activeVariants[address(newVariant)] = true;

        varients[newVariantAddress] = VariantData({
            positionId: tokenId,
            currentTickLower: tick,
            pairedToken: pairedToken,
            poolAddress: poolAddress,
            isToken0: //,
            startTickLower: tick,
            incrementRate: 400, //TODO: generate
            burnRate: 690, //TODO: genetate
            stainNonce: strainNonce,
            variantNonce: variantNonce

        });

        emit VariantCreated(newVariantAddress, pairedToken);
    }

    function addLiquidity(address variantToken, address pairedToken, int24 tick) private returns(uint256 tokenId) {
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
}
