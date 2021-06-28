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

    mapping (address => uint256) variantPositions;
    mapping (address => bool) activeVariants;
    mapping (address => address[]) pairedVariants;
    mapping (uint256 => uint256) strainVariantsCount;
    
    INonfungiblePositionManager public immutable positionManager;
    IUniswapV3Factory public immutable uniswapV3Factory;
    IQuoter public immutable quoter;    
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

    function incrementLiquidity(address variantToken) public override { // raise the price of a variant token by 4%    
        uint256 tokenId = variantPositions[variantToken];
        (,, address token0, address token1,, int24 tickLower,,,,, uint128 tokensOwed0, uint128 tokensOwed1) = positionManager.positions(tokenId);
        address pairedToken = token0 == variantToken ? token1 : token0;
        uint256 result = calculateExcessLiquidity(variantToken, pairedToken);
        
        if (result < 420) { return; }
        
        positionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: devAddress,
            amount0Max: tokensOwed0,
            amount1Max: tokensOwed1 }));

        removeLiquidity(tokenId);

        positionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max }));

        addLiquidity(variantToken, pairedToken, tickLower + 400);
    }

    function calculateExcessLiquidity(address variantToken, address pairedToken) private returns (uint256) {
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
    }

    function eatExoticAnimal() public override {
        address spreader = msg.sender;
        require (activeVariants[spreader], "The animal isn't a spreader");
        uint256 position = variantPositions[spreader];
        (,,,address pairedToken,, int24 tick,,,,,,) = positionManager.positions(position); // push this data to new pool params, will be read within the constructor in the variant launch
        uint256 strainNonce = VariantToken(spreader).strainNonce();
        createNewVariant(pairedToken, tick, strainNonce, ++strainVariantsCount[strainNonce]);
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
        VariantToken newVariant = new VariantToken(strainNonce, variantNonce);
        address newVariantAddress = address(newVariant);
        address poolAddress = positionManager.createAndInitializePoolIfNecessary(newVariantAddress, pairedToken, fee, TickMath.getSqrtRatioAtTick(tick));
        newVariant.setPoolAddress(poolAddress);       
        addLiquidity(newVariantAddress, pairedToken, tick);      
        activeVariants[address(newVariant)] = true;
        pairedVariants[pairedToken].push(newVariantAddress);
        emit VariantCreated(newVariantAddress, pairedToken);
    }

    function addLiquidity(address variantToken, address pairedToken, int24 tick) private {
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
        variantPositions[variantToken] = tokenId;
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
