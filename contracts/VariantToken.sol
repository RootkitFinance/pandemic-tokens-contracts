// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./ILab.sol";

contract VariantToken is ERC20 {   
    using SafeMath for uint256;

    ILab public wuhanLab;
    address public poolAddress;
    uint256 public burnRate;

    constructor(uint256 _burnRate) ERC20("Variant", "COVID") {
        burnRate = _burnRate;
        wuhanLab = ILab(msg.sender);
        _mint(msg.sender, 70e12 ether);
    }

    function setPoolAddress(address _poolAddress) public {
        require (msg.sender == address(wuhanLab), "Not Wuhan Lab");
        poolAddress = _poolAddress;
    }

    function superSpreader() public {
        wuhanLab.incrementLiquidity(address(this));
    }

    function mutateNewVariant() public {
        wuhanLab.eatExoticAnimal();
    }

    //move ERC20 functions diectly here, only import interface, only keep needed functions, similar to UniswapV2ERC20 
    // transfer function requirements
    // - only the factory is exempt from fees and all other restriictions 
    // - sender or receiver must be the pool
    // - burn on transfer
   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        bool isLab = sender == address(wuhanLab) || recipient == address(wuhanLab);
        require (isLab || sender == poolAddress || recipient == poolAddress, "Liquidity locked");

        _beforeTokenTransfer(sender, recipient, amount);
        uint256 remaining = amount;

        if (!isLab) {
            uint256 burn = amount * burnRate / 10000;
            amount = remaining = remaining.sub(burn, "VariantToken: burn too much");
            _burn(sender, burn);
        }
        
        _balanceOf[sender] = _balanceOf[sender].sub(amount, "VariantToken: transfer amount exceeds balance");
        _balanceOf[recipient] = _balanceOf[recipient].add(remaining);
        
        emit Transfer(sender, recipient, remaining);
    }
}
