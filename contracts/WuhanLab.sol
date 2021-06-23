// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./INonfungiblePositionManager.sol";
import "./IUniswapV3Factory.sol";
import "./IQuoter.sol";
import "./VariantToken.sol";

contract WuhanLab is TokensRecoverable {
    using SafeMath for uint256;

    mapping (address => uint256) variantPositions;
    mapping (address => bool) activeVariants;
    
    INonfungiblePositionManager public immutable positionManager;
    IUniswapV3Factory public immutable uniswapV3Factory;
    IQuoter public immutable quoter;    
    IERC20 public immutable rootkit;
    address private immutable devAddress;

    uint24 public constant fee = 200;

    event VariantCreated(address variant, address pairedToken);

    constructor(INonfungiblePositionManager _positionManager, IUniswapV3Factory _uniswapV3Factory, IQuoter _quoter, IERC20 _rootkit) {
        positionManager = _positionManager;
        uniswapV3Factory = _uniswapV3Factory;
        quoter = _quoter;
        rootkit = _rootkit;
        devAddress = msg.sender;
    }

    function incrementLiquidity(address variantToken) public { // raise the price of a variant token by 4%    
        uint256 tokenId = variantPositions[variantToken];
        (,, address token0, address token1,, uint256 tickLower,,,,, uint256 tokensOwed0, uint256 tokensOwed1) = positionManager.positions(tokenId);
        address pairedToken = token0 == variantToken ? token1 : token0;
        uint256 result = calculateExcessLiquidity(variantToken, pairedToken);
        
        if (result < 420) { return; }
        
        positionManager.collect(CollectParams({
            tokenId: tokenId,
            recipient: devAddress,
            amount0Max: tokensOwed0,
            amount1Max: tokensOwed1 }));

        removeLiquidity(positionId);

        positionManager.collect(CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max }));

        addLiquidity(variantToken, pairedToken, tickLower + 400);
    }

    function calculateExcessLiquidity(address variantToken, address pairedToken) private view returns (uint256) {
        IERC20 variant = IERC20(variantToken);
        IERC20 paired = IERC20(pairedToken);
        address pool = uniswapV3Factory.getPool(variantToken, pairedToken, fee);
        uint256 circulatingSupply = variant.totalSupply().sub(variant.balanceOf(pool));
        uint256 quote = quoter.quoteExactInput(abi.encodePacked(variantToken, pairedToken, fee), circulatingSupply);
        uint256 pairedInPool = paired.balanceOf(pool);
        uint256 excessLiquidity = pairedInPool.sub(quote);
        return excessLiquidity.mul(10000).div(pairedInPool).div(10000); // i need to sleep lol
        // circulatingSupply = total supply - UpOnly in pool - collected fees
        // availableLiquidity = tokens in pool
        // After selling circulatingSupply into availableLiquidity - what is percent of availableLiquidity is left over       
    }

    // New Pool Creation

    function eatExoticAnimal() {
        address spreader = msg.sender;
        require (activeVariants[spreader], "The animal has been already eaten");
        uint256 position = variantPositions[spreader];
        (,,,address pairedToken,, uint256 tick,,,,,,) = positionManager.positions(position); // push this data to new pool params, will be read within the constructor in the variant launch
    }

    function labLeak (address newPairedToken, uint128 startingTick) {// no amount of saftey checks can prevent rugs and broken tokens being added, so no checks are done...
        rootkit.transferFrom(msg.sender, address(this), 1 ether); // it costs 1 ROOT to start a virus with a new variant pair
        createNewVariant(newPairedToken, startingTick);
        // maybe we let the user do a buy here to encourage more people to do it
    }

    // interanl Functions
    struct NewPoolParams 
    {
        uint256 startingPrice;
        address pairedToken;
        address 0;
    }

    function checkNewPoolParams() public view returns (uint256, address) {
        return NewPoolParams.startingPrice, NewPoolParams.pairedToken;
    }
    
    function createNewVariant(address pairedToken, uint256 tick) private {
        bytes memory bytecode = type(VariantToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(block.timetamp, token1));
        assembly {
            address newVariant := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        addLiquidity(newVariant, pairedToken, tick)

        allVariants[newVariant] = true;
        emit VariantCreated(newVariant, pairedToken);
    }

    function addLiquidity(address variantToken, address pairedToken, uint256 tick) private {
        (uint256 tokenId,,,) = positionManager.mint(MintParams({
            token0: variantToken,
            token1: pairedToken,
            fee: fee,
            tickLower: tick,
            tickUpper: tick + fee,
            amount0Desired: type(uint128).max,
            amount1Desired: type(uint128).max,
            amount0Min: 0,
            amount1Min: 0,
            address(this),
            block.timestamp
        }));
        variantPositions[variantToken] = tokenId;
    }

    function removeLiquidity(uint256 tokenId) private {      
        (uint256 amount0, uint256 amount1) = positionManager.decreaseLiquidity(DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: type(uint128).max,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        }));
    }
}
