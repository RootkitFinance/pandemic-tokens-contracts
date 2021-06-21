// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./TokensRecoverable.sol";

contract LpStakingToken is ERC20("upUSDT Staking", "xLpUpUSDT"), TokensRecoverable
{
    using SafeMath for uint256;
    IERC31337 public immutable eliteToken;
    IERC20 public immutable baseEliteLpToken;

    constructor(IERC20 _baseEliteLpToken, IERC31337 _eliteToken) 
    {
        baseEliteLpToken = _baseEliteLpToken;
        eliteToken = _eliteToken;
    }

    // Stake baseEliteLpToken, get staking shares
    function stake(uint256 amount) public 
    {
        uint256 totalRooted = baseEliteLpToken.balanceOf(address(this));
        uint256 totalShares = this.totalSupply();

        if (totalShares == 0 || totalRooted == 0) 
        {
            _mint(msg.sender, amount);
        } 
        else 
        {
            uint256 mintAmount = amount.mul(totalShares).div(totalRooted);
            _mint(msg.sender, mintAmount);
        }

        baseEliteLpToken.transferFrom(msg.sender, address(this), amount);
    }

    // Unstake shares, claim back baseEliteLpToken
    function unstake(uint256 share) public 
    {
        uint256 totalShares = this.totalSupply();
        uint256 unstakeAmount = share.mul(baseEliteLpToken.balanceOf(address(this))).div(totalShares);

        _burn(msg.sender, share);
        baseEliteLpToken.transfer(msg.sender, unstakeAmount);
    }

    public compoundLiquidity() public
    {
        // check balance of base vs elite in the contract
        // if (base < elite) 
        // elite.withdraw(50% elite.balanceOf(contract))
        // add liq base.balanceOf(contract) and elite.balanceOf(contract)
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return address(token) != address(this) && address(token) != address(baseEliteLpToken); 
    }
}