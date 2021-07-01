// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.8.6;

import "./IERC20.sol";

contract MicroVirus is IERC20 {

    mapping (address => uint256) internal _balanceOf;

    uint256 public override totalSupply;
    uint256 public price;
    uint256 public lastUpTime;

    string public override name = "Micro Virus"; 
    string public override symbol = "VIV";
    uint8 public override decimals = 18;

    address public immutable virusLauncher;
    address immutable dev;
    IERC20 public immutable pairedToken;
    uint256 public immutable burnRate;
    uint256 public immutable totalFees;
    uint256 public immutable upPercent;
    uint256 public immutable upDelay;
    
    

    constructor(IERC20 _pairedToken, uint256 _burnRate, uint256 _upPercent, uint256 _upDelay, bool _withFee, uint256 _startPrice, address _dev, address _virusLauncher) {
        dev = _dev;
        pairedToken = _pairedToken;
        burnRate = _burnRate;
        totalFees = _burnRate + 111;
        upPercent = _upPercent;
        upDelay = _upDelay;
        if (_withFee) {
            price = _startPrice;
            virusLauncher = _virusLauncher; }
        else { price = 696969696969;
            virusLauncher = _dev; }
    }


    function UpOnly() public {
        require (block.timestamp > lastUpTime + upDelay);
        uint256 supplyBuyoutCost = totalSupply * price; // paired token needed to buy all supply
        uint256 neededToGoUp = pairedToken.balanceOf(address(this)) * (totalFees + 10000) / 10000; // paired token needed to up the market
        if (supplyBuyoutCost < neededToGoUp){
            price += price * upPercent / 10000; 
            lastUpTime = block.timestamp; }
        }

    function buy (uint256 _amount) public { // buy
        address superSmartInvestor = msg.sender;
        pairedToken.transferFrom(superSmartInvestor, address(this), _amount);
        uint256 purchaseAmount = _amount / price;
        _mint(superSmartInvestor, purchaseAmount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        uint256 remaining = amount - amount * totalFees / 10000;
        _balanceOf[account] += remaining;
         _balanceOf[dev] += amount * 42 / 10000;
        _balanceOf[virusLauncher] += amount * 69 / 10000;
        totalSupply += remaining + amount * 111 / 10000;
        emit Transfer(address(0), account, amount);
    }

    function sell(uint256 _amount) public {
        address notGunnaMakeIt = msg.sender;
        _burn(notGunnaMakeIt, _amount);
        uint256 exitAmount = (_amount - _amount * totalFees / 10000) * price;
        pairedToken.transfer(notGunnaMakeIt, exitAmount);
    }

    function _burn(address notGunnaMakeIt, uint amount) internal virtual {
        _balanceOf[notGunnaMakeIt] -= amount;
        _balanceOf[virusLauncher] += amount * 69 / 10000;
         _balanceOf[dev] += amount * 42 / 10000;
        totalSupply -= (amount - amount * 111 / 10000);
        emit Transfer(notGunnaMakeIt, address(0), amount);
    }

    function balanceOf(address a) public virtual override view returns (uint256) {
        return _balanceOf[a]; 
    }

    function recoverTokens(IERC20 token) public {
        require (msg.sender == dev && address(token) != address(this) && address(token) != address(pairedToken));
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}
