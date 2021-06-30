// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./ILab.sol";

contract ViralERC20 is IERC20 {   

    mapping (address => uint256) internal _balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    uint256 public override totalSupply;

    string public override name = "Money Virus";
    string public override symbol = "CMMV";
    uint8 public override immutable decimals = 18;

    //address private strainCreator;
    //address private virusCreator;

    ILab public immutable wuhanLab;
    uint256 public immutable burnRate;
    
    address public poolAddress;


    constructor(uint256 _burnRate) {
        burnRate = _burnRate;
        wuhanLab = ILab(msg.sender);
        totalSupply = 69e13 ether;
        _balanceOf[msg.sender] = 69e13 ether;
    }

    function superSpreader() public {
        wuhanLab.incrementLiquidity(address(this));
    }

    function mutateNewVariant() public {
        wuhanLab.eatExoticAnimal();
    }

    function setPoolAddress(address _poolAddress) public {
        require (msg.sender == address(wuhanLab));
        poolAddress = _poolAddress;
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function balanceOf(address a) public virtual override view returns (uint256) {
        return _balanceOf[a]; 
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        bool isLab = sender == address(wuhanLab) || recipient == address(wuhanLab);
        require (isLab || sender == poolAddress || recipient == poolAddress, "ViralERC20");

        uint256 remaining = amount;

        if (!isLab) {
            uint256 burn = amount * burnRate / 10000;
            amount = remaining = remaining.sub(burn);
            _burn(sender, burn);
        }
        
        _balanceOf[sender] = _balanceOf[sender].sub(amount);
        _balanceOf[recipient] = _balanceOf[recipient].add(remaining);
        
        emit Transfer(sender, recipient, remaining);
    }

    function _burn(address from, uint value) internal {
        _balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function recoverTokens(IERC20 token) public {
        require (msg.sender == address(wuhanLab) && address(token) != address(this));
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

}
