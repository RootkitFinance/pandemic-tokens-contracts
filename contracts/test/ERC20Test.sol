// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "../ERC20.sol";

contract ERC20Test is ERC20("Test", "TST") 
{ 
    constructor()
    {
        _mint(msg.sender, 100 ether);
    }
}