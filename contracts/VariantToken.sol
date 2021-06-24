// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./ERC20.sol";
import "./WuhanLab.sol";

contract VariantToken is ERC20
{
    uint256 public constant burnRate = 690;
    WuhanLab public wuhanLab;
    address public poolAddress;

    constructor() { //TODO: pass/generate name and symbol
        wuhanLab = WuhanLab(msg.sender);
        _mint(msg.sender, 70e12 ether);
    }

    function setPoolAddress(address _poolAddress) {
        require (msg.sender == address(wuhanLab), "Not Wuhan Lab");
        poolAddress = _poolAddress;
    }

    function superSpreader() public {
        wuhanLab.incrementLiquidity(address(this));
    }

    function mutateNewVariant() public {
        wuhanLab.eatExoticAnimal();
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    //move ERC20 functions diectly here, only import interface, only keep needed functions, similar to UniswapV2ERC20 
    // transfer function requirements
    // - only the factory is exempt from fees and all other restriictions 
    // - sender or receiver must be the pool
    // - burn on transfer
    // - require extcode size == 0 .......... = no inline assembly .... we dont want contracts interacting with the tokens
   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        bool isLab = sender == address(wuhanLab) || recipient == address(wuhanLab);
        require (isLab || (sender == poolAddress && !isContract(recipient)) || (recipient == poolAddress && isContract(sender)), "Liquidity locked");

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
