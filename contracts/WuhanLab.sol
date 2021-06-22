// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./TokensRecoverable.sol";
import "./INonfungiblePositionManager.sol";
import "./IQuoter.sol";
import "./VariantToken.sol";

contract WuhanLab is TokensRecoverable
{

    mapping (address => uint256) CurrentVariantPositions;
    address[] public allVariants;

    address private immutable devAddress;
    IERC20 public immutable rootkit
    INonfungiblePositionManager public immutable positionManager;
    IQuoter public immutable quoter;

    event VariantCreated(address variant, address pairedToken);

    constructor(INonfungiblePositionManager _positionManager, IQuoter _quoter, IERC20 _rootkit)
    {
        positionManager = _positionManager;
        quoter = _quoter;
        rootkit = _rootkit;
        devAddress = msg.sender;
    }


    function incrementLiquidity(address variantToken) public { // raise the price of a variant token by 4%
        uint256 positionID = CurrentVariantPositions[variantToken];
        (,,address = token0, address = token1,, uint256 = tick,,,,, uint256 = tokensOwed0, uint256 = tokensOwed1) = positionManager.positions(positionID);
        address pairedToken = token0 == variantToken ? token1 : token0;
        uint256 result = calculateExcessLiquidity(variantToken, pairedToken);
        if (result < 420) { return; }
        positionManager.collect(CollectParams {
            tokenId;
            devAddress;
            tokensOwed0;
            tokensOwed1 });
        removeLiquidity(positionID);
        positionManager.collect(CollectParams {
            tokenId;
            address(this);
            type(uint128).max;
            type(uint128).max });
        addLiquidity(address variantToken, address pairedToken, tick + 400);
    }

    function calculateExcessLiquidity(address variantToken, address pairedToken) private view returns (uint256)
    {
        IERC20(variantToken) = variantToken
        uint256 circulatingSupply = variantToken.totalSupply().sub(variantToken.balanceOf(PoolAddress))
        uint256 out = quoter.quoteExactInput(abi.encodePacked(variantToken, 200, pairedToken), circulatingSupply)
        uint256 excessLiquidity = IERC20(pairedToken).balanceOf(pool).sub(out);
        return excessLiquidity.mul(10000).div(IERC20(pairedToken).balanceOf(pool)).div(10000); // i need to sleep lol
        // circulatingSupply = total supply - UpOnly in pool - collected fees
        // availableLiquidity = tokens in pool
        // After selling circulatingSupply into availableLiquidity - what is percent of availableLiquidity is left over
        
    }


    // New Pool Creation

    function eatAnExoticAnimal() 
    {
        address spreader = msg.sender;
        require allVariants[spreader];
        uint position = CurrentVariantPositions[spreader];
        (,,,address = pairedToken,, uint256 = tick,,,,,,) = positionManager.positions(position); // push this data to new pool params, will be read within the constructor in the variant launch
    }

    function labLeak (address newPairedToken, uint128 startingTick) // no amount of saftey checks can prevent rugs and broken tokens being added, so no checks are done...
        rootkit.transferFrom(msg.sender, address(this), 1 ether); // it costs 1 ROOT to start a virus with a new variant pair
        createNewVariant(address pairedToken, uint256 tick);
        // maybe we let the user do a buy here to encourage more people to do it 



    // interanl Functions
    struct NewPoolParams 
    {
        uint256 startingPrice;
        address pairedToken;
        address 0;
    }

    function checkNewPoolParams() public view returns (uint256, address)
    {
        return NewPoolParams.startingPrice, NewPoolParams.pairedToken;
    }
    
    function createNewVariant(address pairedToken, uint256 tick) internal
    {
        bytes memory bytecode = type(VariantToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(block.timetamp, token1));
        assembly {
            address newVariant := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        addLiquidity(newVariant, pairedToken, tick)

        allVariants.push(newVariant);
        emit VariantCreated(newVariant, pairedToken);
    }

    function addLiquidity(address variantToken, address pairedToken, uint256 tick) internal
    {        
        (uint256 tokenId,,,) = positionManager.mint(MintParams {
            variantToken,
            pairedToken,
            200,
            tick,
            tick+200,
            type(uint128).max,
            type(uint128).max,
            0,
            0,
            address(this),
            block.timestamp
        });
        CurrentVariantPositions[variantToken] = tokenId;
    }

    function removeLiquidity(uint256 tokenID) internal
    {        
        (uint256 amount0, uint256 amount1) = positionManager.decreaseLiquidity(DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 type(uint128).max;
        uint256 0;
        uint256 0;
        uint256 block.timestamp;
        });
    }
}
